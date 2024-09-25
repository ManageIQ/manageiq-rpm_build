#!/usr/bin/env ruby

# This script takes the existing requirements.txt file
# and updates it with the version for our supported packages
#
# USAGE:
#
# 1. Setup environment
#
#     upload bin/requirements.rb and config/requirements.txt to /tmp
#     source /var/lib/manageiq/venv/bin/activate
#     chmod 755 requirements.rb
#
# 2. Determine all python packages provided by rpms (and compare with OS_PACKAGES)
#
#     TODO: may want to grep rpm contents with 'info$' to determine elgibility.
#
#     for pkg in $(rpm -qa | grep python3-) ; do echo "### $pkg" ; rpm -ql $pkg | awk  -F/ '/site-packages/ { print $6 }' | sort -u ; done
#
# 3. Get all module requirements (don't include documentation or testing ones)
#
#     ./requirements.rb ./requirements.txt /usr/lib/python3.9/site-packages/ansible_collections/ > new_requirements.txt
#
# 4. Resolve conflicts and determine if new one is correct
#
#     diff {,new_}requirements.txt
#     # cp new_requirements.txt requirements.txt
#
# 5. Update dev riles
#
#     download /tmp/requirements{.rb,.txt} to local machine
#     create a PR with updates
#
class ParseRequirements
  # this is the list of packages provided by rpms
  # TODO: paramiko
  OS_PACKAGES=%w[
    six dateutil iniparse idna setuptools inotify libcomps chardet decorator pysocks urllib3 requests
    cloud-what systemd dbus gobject gpg pyspnego
  ]
  PACKAGES=%w[
    amazon/aws/requirements.txt
    ansible/netcommon/requirements.txt
    ansible/utils/requirements.txt
    awx/awx/requirements.txt
    azure/azcollection/requirements-azure.txt
    cisco/intersight/requirements.txt
    community/aws/requirements.txt
    community/okd/requirements.txt
    community/vmware/requirements.txt
    google/cloud/requirements.txt
    kubernetes/core/requirements.txt
    openstack/cloud/requirements.txt
    ovirt/ovirt/requirements.txt
    theforeman/foreman/requirements.txt
    vmware/vmware_rest/requirements.txt
  ]
  attr_reader :filenames, :non_modules, :final, :verbose

  def initialize
    @filenames = []
    @non_modules = []

    @final = {}
    @verbose = false
  end

  def verbose!
    @verbose = true
  end

  def add_target(filename)
    if Dir.exist?(filename)
      add_dir(filename)
    elsif File.exist?(filename)
      add_file(filename)
    else
      $stderr.puts("File not found: #{filename}")
    end
  end

  def add_file(filename)
    @filenames << filename
    @non_modules << filename unless filename.include?("ansible_collections")

    self
  end

  def add_dir(dirname)
    dirname = dirname[0..-2] if dirname.end_with?("/")
    PACKAGES.each do |package|
      filename = "#{dirname}/#{package}"
      if File.exist?(filename)
        @filenames << filename
      else
        $stderr.puts("NOTICE: missing #{filename}")
      end
    end

    self
  end

  def parse
    filenames.each do |fn|
      # the list of requirements-files can have items commented out - ignore those

      mod = module_name_from_filename(fn)
      IO.foreach(fn, chomp: true).each do |line|
        lib, ver = parse_line(line)
        next unless lib

        # skip git libraries. git>= line from vsphere gave us problems
        next if lib.start_with?("git")

        # system packages are versioned by rpms
        ver = "" if lib.match?(/^(#{OS_PACKAGES.join("|")})($|\[)/)

        final[lib] ||= {}
        (final[lib][ver] ||= []) << mod
      end
    end

    self
  end

  def output
    result = final.flat_map do |lib, vers|
      # consolidate multiple versioning rules
      if vers.size > 1
        max_key, *all_keys = vers.keys
        all_keys.each do |alt|
          higher, lower, conflict = version_compare(alt, max_key)
          # There is a conflict when we have conflicting requirements. eg: >=2.0 and ==1.0
          # We are displaying all comparisons/winners to verify the comparison algorithm works (skipping when merging a blank - no change of errors there)
          $stderr.puts "#{lib}: #{higher} > #{lower} #{"CONFLICT" if conflict}" if lower != "" || verbose
          vers[higher].concat(vers.delete(lower))
          max_key = higher
        end
      end

      ver = vers.keys.first
      modules = vers[ver]
      # if we pass in a previous requirements.txt, lets not mention it
      # exception: display if it is only mentioned in a previous requirements.txt file
      modules.delete("legacy") if modules.size > 1

      # clear out versions for packages provided by the operatingsystem like requests, requests[security], and pyspnego
      ver = "" if OS_PACKAGES.include?(lib.gsub(/\[.*\]/))

      "#{lib}#{ver} # #{modules.join(", ")}"
    end.sort.join("\n")

    puts result
  end

  private

  def module_name_from_filename(fn)
    if non_modules.include?(fn)
      "legacy"
    else
      fn.gsub(%r{.*ansible_collections/}, "")
        .gsub(%r{/requirements.*}, "")
    end
  end

  def parse_line(line)
    line.downcase!
    # TODO: do we want to keep legacy comments? Only useful for our requirements.txt file
    line.gsub!(/#.*/, "")
    line.strip!
    return if line.empty?

    # Some libraries list "python" instead of "python_version"
    # Dropping since just listing the python version isn't useful
    return if line.match?(/^python([ <=>]|_version)/)

    # Some libraries list version "5+" instead of ">=5"
    line.gsub!(/\([0-9.]*\)\+/, '>=\1')
    line.gsub!("= ", "=")
    # Ignore package requirements for older version of pythons (assumption here)
    return if line.match?(/python_version ?[=<]/)

    lib, ver = split_lib_ver(line)

    # Note: Already normalized for lowercase
    # Normalize library name with dash. All these characters are treated the same.
    lib.gsub!(/[-_.]+/, "-")
    ver ||= ""

   # TODO: split off ;python_version in split_lib_version - evaluate it properly
   return if ver.match?(/python_version *[=<]/)

    [lib, ver]
  end

  # ipaddress>=1.0,<=2.0;python_version<3.0
  # currently returning  "ipaddress", ">=1.0,<=2.0;python_version<3.0"
  # @return lib, version
  def split_lib_ver(line)
    # split on first space (or =)
    # version can have multiple spaces
    lib, ver = line.match(/([^ >=]*) ?(.*)/).captures

    [lib, ver]
  end

  # @return [Numeric, Numeric, Boolean]
  #   highest, lowest for version comparison
  #   boolean is true if there is a conflict with the versions
  def version_compare(a, b)
    winner = a if a.start_with?("==")
    winner = b if b.start_with?("==")
    # due to the way zip works, we need the longer to be on the left of the split
    a, b = b, a if a.split(".").length < b.split(".").length

    # when comparing, drop off the >= or == stuff, just look at the numbers
    # kinda assuming that we are dealing mostly with >=
    # reminder <=> returns -1, 0, +1 like standard `cmp` functionality from c.
    cmp = a.gsub(/^[=<>]+/, "").split(".").zip(b.gsub(/^[=<>]+/, "").split(".")).inject(0) { |acc, (v1, v2)| acc == 0 ? v1.to_i<=>v2.to_i : acc }

    # ensure a >= b
    a, b = b, a if cmp < 0

    [a, b, winner && winner != a]
  end
end

# {"lib" => {ver => [module]}}

pr = ParseRequirements.new
ARGV.each { |arg| pr.add_target(arg) }
pr.verbose! if ENV["VERBOSE"]
pr.parse.output
