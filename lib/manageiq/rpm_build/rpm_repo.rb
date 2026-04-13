require 'droplet_kit'

module ManageIQ
  module RPMBuild
    class RpmRepo
      include Helper
      include S3Common

      def update
        require 'tempfile'
        Dir.mktmpdir do |tmpdir|
          work_dir = Pathname.new(tmpdir)
          cache_base = work_dir.join("createrepo_cache")

          # Build directory structure /release/{master,jansa}/el9/{noarch,src,x86_64}
          directories = OPTIONS.rpm_repository.content.flat_map do |branch, values|
            values[:targets].product(OPTIONS.rpm_repository.arches).map do |target, arch|
              work_dir.join("release", branch.to_s, target, arch)
            end
          end
          require 'fileutils'
          directories.each { |dir| FileUtils.mkdir_p(dir) }
          FileUtils.mkdir_p(cache_base)

          # Download createrepo cache from S3
          puts "Downloading createrepo cache from S3..."
          download_createrepo_cache(cache_base)

          # Copy only NEW RPMs to work directory
          puts "Copying new RPMs to repository directories..."
          new_rpms = []
          OPTIONS.rpm_repository.content.each do |branch, values|
            values[:rpms]&.each do |rpm, version_regex|
              client.list_objects(:bucket => OPTIONS.rpm_repository.s3_api.bucket, :prefix => File.join("builds", rpm.to_s, "/")).flat_map(&:contents).each do |object|
                file = object.key
                name = File.basename(file)
                *, target, arch, _rpm = name.split(".")
                next unless values[:targets].include?(target)
                next unless OPTIONS.rpm_repository.arches.include?(arch)
                next unless version_regex =~ name

                destination = work_dir.join("release", branch.to_s, target, arch, name)

                # Check if RPM already exists in S3 repository
                s3_rpm_key = File.join("release", branch.to_s, target, arch, name)
                if remote_etag(s3_rpm_key)
                  puts "  Skipping existing RPM: #{name}"
                  next
                end

                # This is a new RPM - download it
                cached_rpm = ROOT_DIR.join("rpm_cache", name)
                unless cached_rpm.file?
                  puts "  Fetching new RPM: #{name}"
                  client.get_object(:bucket => OPTIONS.rpm_repository.s3_api.bucket, :key => file, :response_target => cached_rpm)
                end
                FileUtils.cp(cached_rpm, destination)
                new_rpms << destination
              end
            end
          end

          if new_rpms.empty?
            puts "No new RPMs to process"
            return
          end

          puts "Found #{new_rpms.size} new RPM(s) to add to repository"

          # puts "Signing release RPMs..."
          # shell_cmd("rpmsign -D '%_gpg_name #{OPTIONS.rpm_repository.gpg_signing_id}' --addsign #{work_dir.join("release", "*", "*", "*", "*.rpm")}")

          # Update repo metadata using cache
          puts "Updating repository metadata with createrepo --update..."
          directories.each do |dir|
            # Skip directories with no new RPMs
            next unless Dir.glob(dir.join("*.rpm")).any?

            relative_path = dir.relative_path_from(work_dir).to_s.gsub("/", "_")
            cache_dir = cache_base.join(relative_path)
            FileUtils.mkdir_p(cache_dir)

            shell_cmd("createrepo --update --cachedir #{cache_dir} #{dir}")
            # shell_cmd("gpg -u security@manageiq.org --detach-sign --yes --armor #{File.join(dir, 'repodata', 'repomd.xml')}")
          end

          # Upload new RPMs and updated metadata
          require 'digest'
          puts "Uploading new RPMs and updated metadata..."
          uploaded_files = []

          # Upload new RPMs
          new_rpms.each do |rpm_path|
            destination_name = rpm_path.to_s.sub("#{work_dir.to_s}/", '')
            uploaded_files << destination_name if upload_file(rpm_path, destination_name)
          end

          # Upload updated repodata
          Dir.glob(work_dir.join('release', '**', 'repodata', '*')).each do |file|
            next unless File.file?(file)
            destination_name = file.sub("#{work_dir.to_s}/", '')
            uploaded_files << destination_name if upload_file(file, destination_name)
          end

          # Upload updated createrepo cache back to S3
          puts "Uploading updated createrepo cache to S3..."
          Dir.glob(cache_base.join('**', '*')).each do |file|
            next unless File.file?(file)
            relative_path = file.sub("#{cache_base.to_s}/", '')
            destination_name = File.join("createrepo_cache", relative_path)
            upload_file(file, destination_name)
          end

          puts "Repository update complete. Uploaded #{uploaded_files.size} file(s)."
        end
      end

      private

      def download_createrepo_cache(cache_base)
        # Download existing createrepo cache from S3
        client.list_objects(:bucket => OPTIONS.rpm_repository.s3_api.bucket, :prefix => "createrepo_cache/").flat_map(&:contents).each do |object|
          next if object.key.end_with?('/')

          relative_path = object.key.sub("createrepo_cache/", '')
          local_path = cache_base.join(relative_path)

          FileUtils.mkdir_p(File.dirname(local_path))
          puts "  Downloading cache: #{relative_path}"
          client.get_object(:bucket => OPTIONS.rpm_repository.s3_api.bucket, :key => object.key, :response_target => local_path)
        end
      rescue Aws::S3::Errors::NoSuchKey
        puts "  No existing cache found (this is normal for first run)"
      end
    end
  end
end
