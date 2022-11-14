module ManageIQ
  module RPMBuild
    class ExtraPackage
      require 'pathname'
      PACKAGES_DIR = Pathname.new(__dir__).join("..", "..", "..", "packages").freeze

      attr_reader :package

      def initialize(package)
        @package = package
      end

      def run_build
        fetch_sources
        build
        copy_results
      end

      def config
        @config ||= MockConfig.new(package)
      end

      def fetch_sources
        sources_file = PACKAGES_DIR.join(package, "sources")
        return unless sources_file.exist?

        File.read(sources_file).each_line do |source|
          next if source.strip.empty?

          fetch_source(source)
        end
      end

      def fetch_source(source)
        expected_sha, file_name = source.split
        local_file  = PACKAGES_DIR.join(package, file_name)
        remote_file = File.join("https://rpm.manageiq.org/sources_cache", package, file_name)

        require 'open-uri'
        print "Fetching #{file_name}... "
        File.open(local_file, 'wb') { |file| file << URI.parse(remote_file).open.read }
        puts "complete."

        print "Verifying #{file_name}... "
        sha512 = Digest::SHA512.file(local_file).hexdigest
        if sha512 == expected_sha
          puts "complete."
        else
          raise("Digest mismatch for #{local_file}")
        end
      end

      def build
        Dir.chdir(PACKAGES_DIR.join(package).expand_path) do
          build_command = assemble_build_command
          puts "Building with: #{build_command}"
          system(build_command)
        end
      end

      def assemble_build_command
        specfile = Dir[PACKAGES_DIR.join(package, "*.spec").expand_path].first
        "mock -r #{config.mock_config} --sources=./ --spec=#{File.basename(specfile)}".tap do |cmd|
          cmd << " #{config.merged_config[:mock_extras]}" if config.merged_config[:mock_extras]
        end
      end

      def copy_results
        require 'fileutils'
        results_dir = "/var/lib/mock/#{config.mock_config}/result"
        Dir[File.join(results_dir, "*.rpm")].each do |file|
          FileUtils.cp(file, PACKAGES_DIR.join("..", "rpm_cache"))
        end
      end

      class MockConfig
        RAW = {
          :defaults     => {
            :arch       => RUBY_PLATFORM.split("-")[0],
            :os         => "centos-stream",
            :os_version => "8",
          },
          "kafka"       => {
            :mock_extras => "--enable-network",
            :os          => "centos-stream+epel",
          },
          "qpid-proton" => {
            :os => "centos-stream+epel",
          },
          "repmgr13"    => {
            :os => "centos-stream+epel",
          }
        }.freeze

        attr_reader :merged_config

        def initialize(package)
          @merged_config = RAW[:defaults].merge(RAW[package] || {})
        end

        def mock_config
          merged_config.values_at(:os, :os_version, :arch).join("-")
        end
      end
    end
  end
end
