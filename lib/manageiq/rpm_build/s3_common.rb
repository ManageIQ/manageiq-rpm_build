module ManageIQ
  module RPMBuild
    module S3Common
      private

      def client
        @client ||= begin
          require 'aws-sdk-s3'
          Aws::S3::Resource.new(
            :credentials => Aws::Credentials.new(OPTIONS.rpm_repository.s3_api.access_key, OPTIONS.rpm_repository.s3_api.secret_key),
            :region      => 'us-east',
            :endpoint    => "https://#{OPTIONS.rpm_repository.s3_api.endpoint}"
          ).client
        end
      end

      def remote_etag(key)
        client.head_object(
          :bucket => OPTIONS.rpm_repository.s3_api.bucket,
          :key    => key
        )[:etag].tr("\\\"", "")
      rescue Aws::S3::Errors::NotFound
      end

      def upload_file(source, destination)
        require 'digest'
        md5sum = Digest::MD5.file(source).hexdigest

        if md5sum == remote_etag(destination)
          puts "  Skipping existing file: #{destination}"
          return false
        end

        puts "  Uploading: #{destination}"
        File.open(source, 'rb') do |content|
          client.put_object(
            :bucket => OPTIONS.rpm_repository.s3_api.bucket,
            :key    => destination,
            :body   => content,
            :acl    => 'public-read'
          )
        end
        return true
      end
    end
  end
end
