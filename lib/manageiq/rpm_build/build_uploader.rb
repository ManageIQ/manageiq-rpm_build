module ManageIQ
  module RPMBuild
    class BuildUploader
      include S3Common
      attr_reader :release

      def initialize(options = {})
        @release = options[:release]
      end

      def upload
        return unless OPTIONS.rpm_repository.s3_api.access_key && OPTIONS.rpm_repository.s3_api.secret_key

        puts "Uploading files..."
        BUILD_DIR.glob(File.join('**', '*.rpm')).sort.each do |file|
          product_directory = release ? OPTIONS[:product_name] : "#{OPTIONS[:product_name]}-nightly"
          destination_name  = File.join("builds", product_directory, File.basename(file))

          upload_file(file, destination_name)
        end
      end
    end
  end
end
