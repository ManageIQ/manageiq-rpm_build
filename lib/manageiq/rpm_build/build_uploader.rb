module ManageIQ
  module RPMBuild
    class BuildUploader
      attr_reader :release

      def initialize(options = {})
        @release = options[:release]
      end

      def upload
        return unless OPTIONS.rpm_repository.s3_api.access_key && OPTIONS.rpm_repository.s3_api.secret_key

        require 'digest'
        puts "Uploading files..."
        BUILD_DIR.glob(File.join('**', '*.rpm')).each do |file|
          product_directory = release ? OPTIONS[:product_name] : "#{OPTIONS[:product_name]}-nightly"
          destination_name = File.join("builds", product_directory, File.basename(file))
          md5sum = Digest::MD5.file(file).hexdigest

          if md5sum == remote_etag(destination_name)
            puts "  Skipping existing file: #{destination_name}"
          else
            puts "  Uploading: #{destination_name}"
            File.open(file, 'rb') do |content|
              client.put_object(
                :bucket => OPTIONS.rpm_repository.s3_api.bucket,
                :key    => destination_name,
                :body   => content,
                :acl    => 'public-read'
              )
            end
          end
        end
      end

      private

      def client
        @client ||= begin
          require 'aws-sdk-s3'
          Aws::S3::Client.new(
            :access_key_id     => OPTIONS.rpm_repository.s3_api.access_key,
            :secret_access_key => OPTIONS.rpm_repository.s3_api.secret_key,
            :region            => 'us-east-1',
            :endpoint          => "https://#{OPTIONS.rpm_repository.s3_api.endpoint}"
          )
        end
      end

      def remote_etag(key)
        client.head_object(
          :bucket => OPTIONS.rpm_repository.s3_api.bucket,
          :key    => key
        )[:etag].tr("\\\"", "")
      rescue Aws::S3::Errors::NotFound
      end
    end
  end
end
