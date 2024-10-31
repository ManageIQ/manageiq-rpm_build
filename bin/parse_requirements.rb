#!/usr/bin/env ruby

# This script takes the existing requirements.txt file
# and updates it with the version for our supported packages
#
# USAGE:
#
# 1. Setup environment
#
#     upload bin/parse_requirements.rb and config/requirements.txt to /tmp
#     source /var/lib/manageiq/venv/bin/activate
#     chmod 755 parse_requirements.rb
#
# 2. Get all module requirements
#
#     ./parse_requirements.rb ./requirements.txt /usr/lib/python3.9/site-packages/ansible_collections/ > new_requirements.txt
#
# 3. Resolve conflicts and determine if new one is correct
#    double check that the legacy ones are still needed
#
#     diff {,new_}requirements.txt
#     # cp new_requirements.txt requirements.txt
#
# 4. Update dev files
#
#     download /tmp/requirements.txt to local machine
#     create a PR with updates
#
class ParseRequirements
  # this is the list of supported collections
  PACKAGES = %w[
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
  ].freeze
  attr_reader :filenames, :non_modules, :final, :verbose

  # These packages are installed via rpm
  def os_packages
    # Leaving this as pure bash so we can run from the command line to fix issues.
    @os_packages ||=
      `rpm -ql $(rpm -qa | grep python3- | sort) | awk  -F/ '/site-packages.*-info$/ { print $6 }' | sed 's/-[0-9].*//' | tr '_A-Z' '-a-z' | sort -u`.chomp.split
  end

  def os_package_regex
    @os_package_regex ||= Regexp.union(os_packages)
  end

  # for test
  def os_packages=(values)
    @os_packages = values
    @os_package_regex = nil
  end

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
      warn("File not found: #{filename}")
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
        warn("NOTICE: missing #{filename}")
      end
    end

    self
  end

  def add_line(line, mod)
    lib, ver = parse_line(line)
    return unless lib

    final[lib] ||= {}
    (final[lib][ver] ||= []) << mod
  end

  def parse
    filenames.each do |filename|
      mod = module_name_from_filename(filename)
      File.foreach(filename, :chomp => true).each do |line|
        add_line(line, mod)
      end
    end

    self
  end

  def output
    result = final.flat_map do |lib, vers|
      ver, modules = consolidate_vers(vers, :lib => lib)

      "#{lib}#{ver} # #{modules.join(", ")}"
    end.sort.join("\n")

    puts result
  end

  private

  def module_name_from_filename(filename)
    if non_modules.include?(filename)
      "legacy"
    else
      filename.gsub(%r{.*ansible_collections/}, "")
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

    # NOTE: Already normalized for lowercase
    # Normalize library name with dash. All these characters are treated the same.
    lib.gsub!(/[-_.]+/, "-")
    ver ||= ""

    # TODO: split off ;python_version in split_lib_version - evaluate it properly
    return if ver.match?(/python_version *[=<]/)

    # Skip git libraries. The 'git>=.*' line from vsphere gave us problems.
    return if lib.start_with?("git")

    # Defer to version requirements provided by rpm system packages.
    ver = "" if lib.match?(/^(#{os_package_regex})($|\[)/)

    [lib, ver]
  end

  # ipaddress>=1.0,<=2.0;python_version<3.0
  # currently returning  "ipaddress", ">=1.0,<=2.0;python_version<3.0"
  # @return lib, version
  def split_lib_ver(line)
    # split on first space (or =)
    # version can have multiple spaces
    lib, ver = line.match(/([^ >=]*) ?(.*)/).captures
    # azure uses ==, we are instead using >=
    ver.gsub!("==", ">=")

    [lib, ver]
  end

  # @return [Numeric, Numeric]
  #   highest, lowest for version comparison
  #   boolean is true if there is a conflict with the versions
  def version_compare(left, right)
    # due to the way zip works, we need the longer to be on the left of the split
    left, right = right, left if left.split(".").length < right.split(".").length

    # reminder <=> returns -1, 0, +1 like standard `cmp` functionality from c.
    cmp = left.gsub(/^[=<>]+/, "").split(".").zip(right.gsub(/^[=<>]+/, "").split(".")).inject(0) { |acc, (v1, v2)| acc == 0 ? v1.to_i <=> v2.to_i : acc }

    # ensure a >= b
    left, right = right, left if cmp < 0

    [left, right]
  end

  # consolidate multiple versioning rules
  def consolidate_vers(vers, lib: nil)
    if vers.size > 1
      max_key, *all_keys = vers.keys
      all_keys.each do |alt|
        higher, lower = version_compare(alt, max_key)
        # There is a conflict when we have conflicting requirements. eg: >=2.0 and ==1.0
        # We are displaying all comparisons/winners to verify the comparison algorithm works (skipping when merging a blank - no change of errors there)
        warn("#{lib}: #{higher} > #{lower}") if lower != "" || verbose
        vers[higher].concat(vers.delete(lower))
        max_key = higher
      end
    end

    ver = vers.keys.first
    modules = vers[ver]
    # Only display "legacy" for requirements:
    #   - Listed in the legacy requirements.txt
    #   - Not listed in any collection requirements.txt
    modules.delete("legacy") if modules.size > 1

    [ver, modules]
  end
end

# {"lib" => {ver => [module]}}
if $PROGRAM_NAME == __FILE__
  pr = ParseRequirements.new
  warn("system packages:", pr.os_packages.join(" "), "") if ENV["VERBOSE"]
  ARGV.each { |arg| pr.add_target(arg) }
  pr.verbose! if ENV["VERBOSE"]
  pr.parse.output
end
