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
            values[:rpms]&.each do |rpm, version_regex|
              client.list_objects(:bucket => OPTIONS.rpm_repository.s3_api.bucket, :prefix => File.join("builds", rpm.to_s)).contents.each do |object|
                file = object.key
                name = File.basename(file)
                *, target, arch, _rpm = name.split(".")
                next unless values[:targets].include?(target)
                next unless version_regex =~ name
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
          uploaded_files = []
          Dir.glob(work_dir.join('**', '*')).each do |file|
            next unless File.file?(file)
            destination_name = file.sub("#{work_dir.to_s}/", '')

            uploaded_files << destination_name if upload_file(file, destination_name)
          end

          # Cleanup old stuff online
          puts "Cleaning old files in bucket..."
          OPTIONS.rpm_repository.content.keys.each do |key|
            prefix = File.join("release", key.to_s)
            puts "Cleaning #{prefix}:"
            client.list_objects(:bucket => OPTIONS.rpm_repository.s3_api.bucket, :prefix => prefix).contents.each do |object|
              next if File.file?(work_dir.join(object.key))
              puts "  removing #{object.key}"
              client.delete_object(:bucket => OPTIONS.rpm_repository.s3_api.bucket, :key => object.key)
            end
          end

          # Bust the cache for updated files
          if OPTIONS.rpm_repository.digitalocean_access_token
            puts "Purging the cache for files that were uploaded"
            require 'droplet_kit'
            digitalocean_client = DropletKit::Client.new(:access_token => OPTIONS.rpm_repository.digitalocean_access_token)
            cdn_id = digitalocean_client.cdns.all.detect { |i| i.origin == "#{OPTIONS.rpm_repository.s3_api.bucket}.#{OPTIONS.rpm_repository.s3_api.endpoint}" }.id
            digitalocean_client.cdns.flush_cache(:id => cdn_id, :files => uploaded_files)
          end
        end
      end
    end
  end
end
