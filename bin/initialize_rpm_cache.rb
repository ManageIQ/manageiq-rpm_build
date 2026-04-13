#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'bundler/setup'
require 'manageiq-rpm_build'

module ManageIQ
  module RPMBuild
    class RpmCacheInitializer
      include Helper
      include S3Common

      def initialize
        @cache_dir = ROOT_DIR.join("rpm_cache")
      end

      def run
        require 'tempfile'
        Dir.mktmpdir do |tmpdir|
          work_dir = Pathname.new(tmpdir)

          # Build directory structure /release/{master,jansa}/el9/{noarch,src,x86_64}
          directories = OPTIONS.rpm_repository.content.flat_map do |branch, values|
            values[:targets].product(OPTIONS.rpm_repository.arches).map do |target, arch|
              work_dir.join("release", branch.to_s, target, arch)
            end
          end
          require 'fileutils'
          directories.each { |dir| FileUtils.mkdir_p(dir) }

          # Fetch ALL configured RPMs (one-time download)
          puts "Downloading ALL RPMs for initial cache generation..."
          OPTIONS.rpm_repository.content.each do |branch, values|
            values[:rpms]&.each do |rpm, version_regex|
              client.list_objects(:bucket => OPTIONS.rpm_repository.s3_api.bucket, :prefix => File.join("builds", rpm.to_s, "/")).flat_map(&:contents).each do |object|
                file = object.key
                name = File.basename(file)
                *, target, arch, _rpm = name.split(".")
                next unless values[:targets].include?(target)
                next unless OPTIONS.rpm_repository.arches.include?(arch)
                next unless version_regex =~ name

                cached_rpm = @cache_dir.join(name)
                unless cached_rpm.file?
                  puts "Fetching RPM: #{name}"
                  FileUtils.mkdir_p(@cache_dir)
                  client.get_object(:bucket => OPTIONS.rpm_repository.s3_api.bucket, :key => file, :response_target => cached_rpm)
                end

                destination = work_dir.join("release", branch.to_s, target, arch, name)
                FileUtils.cp(cached_rpm, destination)
              end
            end
          end

          # Generate initial repo metadata with cache
          puts "Generating initial repository metadata with cache..."
          cache_base = work_dir.join("createrepo_cache")
          FileUtils.mkdir_p(cache_base)

          directories.each do |dir|
            # Create a unique cache directory for each repo
            relative_path = dir.relative_path_from(work_dir).to_s.gsub("/", "_")
            cache_dir = cache_base.join(relative_path)
            FileUtils.mkdir_p(cache_dir)

            puts "Creating repo: #{dir}"
            shell_cmd("createrepo --cachedir #{cache_dir} #{dir}")
          end

          # Upload the cache directories to S3
          puts "Uploading createrepo cache to S3..."
          Dir.glob(cache_base.join('**', '*')).each do |file|
            next unless File.file?(file)
            relative_path = file.sub("#{cache_base.to_s}/", '')
            destination_name = File.join("createrepo_cache", relative_path)

            upload_file(file, destination_name)
          end

          puts "\nInitial cache generation complete!"
          puts "Cache has been uploaded to S3 under 'createrepo_cache/' prefix"
        end
      end
    end
  end
end

ManageIQ::RPMBuild::RpmCacheInitializer.new.run

# Made with Bob
