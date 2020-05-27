module ManageIQ
  module RPMBuild
    class RpmRepo
      include Helper
      include S3Common

      def update
        require 'tempfile'
        Dir.mktmpdir do |tmpdir|
          work_dir = Pathname.new(tmpdir)

          # Build directory structure /release/{master,jansa}/el8/{noarch,src,x86_64}
          directories = OPTIONS.rpm_repository.content.flat_map do |branch, values|
            values[:targets].product(OPTIONS.rpm_repository.arches).map do |target, arch|
              work_dir.join("release", branch.to_s, target, arch)
            end
          end
          require 'fileutils'
          directories.each { |dir| FileUtils.mkdir_p(dir) }

          # Fetch the configured RPMs
          puts "Downloading required RPMs..."
          OPTIONS.rpm_repository.content.each do |branch, values|
            values[:rpms]&.each do |rpm, versions|
              client.list_objects(:bucket => OPTIONS.rpm_repository.s3_api.bucket, :prefix => File.join("builds", rpm.to_s)).contents.each do |object|
                file = object.key
                name = File.basename(file)
                *, target, arch, _rpm = name.split(".")
                next unless values[:targets].include?(target)
                next unless versions.any? { |v| name.include?(v.to_s) }
                cached_rpm = ROOT_DIR.join("rpm_cache", name)
                unless cached_rpm.file?
                  puts "Fetching uncached RPM: #{name}"
                  client.get_object(:bucket => OPTIONS.rpm_repository.s3_api.bucket, :key => file, :response_target => cached_rpm)
                end
                destination = work_dir.join("release", branch.to_s, target, arch, name)
                FileUtils.cp(cached_rpm, destination)
              end
            end
          end

          # puts "Signing release RPMs..."
          # shell_cmd("rpmsign -D '%_gpg_name #{OPTIONS.rpm_repository.gpg_signing_id}' --addsign #{work_dir.join("release", "*", "*", "*", "*.rpm")}")

          # Generate repo data
          puts "Generating repository metadata..."
          directories.each do |dir|
            shell_cmd("createrepo #{dir}")
            # shell_cmd("gpg -u security@manageiq.org --detach-sign --yes --armor #{File.join(dir, 'repodata', 'repomd.xml')}")
          end

          # Upload
          require 'digest'
          puts "Uploading files..."
          Dir.glob(work_dir.join('**', '*')).each do |file|
            next unless File.file?(file)
            destination_name = file.sub("#{work_dir.to_s}/", '')

            upload_file(file, destination_name)
          end

          # Cleanup old stuff online
          puts "Cleaning old files in bucket..."
          client.list_objects(:bucket => OPTIONS.rpm_repository.s3_api.bucket).contents.each do |object|
            next unless object.key.start_with?("release/")
            next if File.file?(work_dir.join(object.key))
            client.delete_object(:bucket => OPTIONS.rpm_repository.s3_api.bucket, :key => object.key)
          end
        end
      end
    end
  end
end
