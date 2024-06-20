module ManageIQ
  module RPMBuild
    class BuildContainers
      include Helper

      attr_reader :manifest_dir

      def initialize
        where_am_i

        @manifest_dir = MANIFEST_DIR
      end

      def build
        where_am_i
      end
    end
  end
end
