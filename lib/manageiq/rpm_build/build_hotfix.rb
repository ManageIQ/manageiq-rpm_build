require 'awesome_spawn'
require 'fileutils'
require 'pathname'
require 'yaml'

module ManageIQ
  module RPMBuild
    class BuildHotfix
      include Helper

      attr_reader :rpm_spec

      def generate_rpm
        where_am_i

        Dir.chdir(HOTFIX_DIR) do
          clean_hotfix_directory
          unpack_srpm
          update_spec
          copy_patches

          arch = RUBY_PLATFORM.split("-").first
          shell_cmd("rpmbuild -ba --define '_sourcedir #{HOTFIX_DIR}' --define '_srcrpmdir #{BUILD_DIR.join("rpms", arch)}' --define '_rpmdir #{BUILD_DIR.join("rpms")}' #{rpm_spec}")
        end
      end

      private

      def copy_patches
        FileUtils.cp(patches, HOTFIX_DIR)
      end

      def patches
        @patches ||= Dir.glob(ManageIQ::RPMBuild::ROOT_DIR.join("rpm_spec", "patches", "*.patch"))
      end

      def update_spec
        where_am_i

        spec_text = File.read(rpm_spec)

        # We need a release number greater than the previous, but less than the next official release.
        # I'd be surprised if we had more than 99 patch files in a hotfix release,
        # so change out the timestamp minutes to 99 and the seconds to the number of patches.
        # This allows for multiple hotfixes on the same original RPM and each to have a predictable release number greater than the last.
        old_release = spec_text.match(/^Release:\s+(\d{14}).*/)[1]
        new_release = old_release[0...10] + (9900 + patches.length).to_s
        spec_text.sub!(/^Release:.*$/, "Release:  #{new_release}%{dist}")

        patch_list_lines = patches.each_with_index.collect { |patch, i| "Patch#{i + 1}: #{patch}\n" }
        spec_text.sub!(/.*Source4:.+\n/) { |match| "#{match}#{patch_list_lines.join}" }

        patch_apply_lines = patches.each_with_index.collect { |patch, i| "%patch -P #{i + 1} -p1\n"}
        spec_text.sub!(/cd %{_builddir}\n/) { |match| "#{match}#{patch_apply_lines.join}" }

        version = spec_text.match(/Version:\s+(.*)/)[1]
        changelog_entry = <<~EOC
          * #{Time.now.strftime("%a %b %d %Y")} Hot Fix <hotfix@example.com> - #{version}-#{new_release}
          - Fixes on top of #{version}-#{old_release}

          EOC

        spec_text.sub!(/%changelog\n/) { |match| "#{match}#{changelog_entry}" }

        File.write(rpm_spec, spec_text)
      end

      def clean_hotfix_directory
        files = Dir.glob("*[!.src.rpm]")
        FileUtils.rm_f(files, :verbose => true)
      end

      def unpack_srpm
        srpm = Dir.glob("*.src.rpm").first
        shell_cmd("rpm2cpio #{srpm} | cpio -idmv")
        @rpm_spec = Dir.glob("*.spec").first
      end
    end
  end
end
