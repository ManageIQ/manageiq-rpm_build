require 'config'
require 'pathname'
require 'yaml'

require 'term/ansicolor'
class String
  include Term::ANSIColor
end

require 'manageiq/rpm_build/s3_common'

require 'manageiq/rpm_build/helper'
require 'manageiq/rpm_build/build_copr'
require 'manageiq/rpm_build/build_hotfix'
require 'manageiq/rpm_build/build_uploader'
require 'manageiq/rpm_build/generate_ansible_venv'
require 'manageiq/rpm_build/generate_gemset'
require 'manageiq/rpm_build/generate_tar_files'
require 'manageiq/rpm_build/nightly_build_purger'
require 'manageiq/rpm_build/rpm_repo'
require 'manageiq/rpm_build/setup_source_repos'

module ManageIQ
  module RPMBuild
    ROOT_DIR     = Pathname.new("../..").expand_path(__dir__)
    CONFIG_DIR   = ROOT_DIR.join("config")
    SCRIPT_DIR   = ROOT_DIR.join("scripts")

    BUILD_DIR    = Pathname.new(ENV.fetch("BUILD_DIR", "~/BUILD")).expand_path
    HOTFIX_DIR   = BUILD_DIR.join("hotfix")
    RPM_SPEC_DIR = BUILD_DIR.join("rpm_spec")
    MANIFEST_DIR = BUILD_DIR.join("manifest")

    OPTIONS_DIR  = Pathname.new(ENV.fetch("OPTIONS_DIR", "~/OPTIONS")).expand_path
    OPTIONS      = Config.load_files(CONFIG_DIR.join("options.yml"), OPTIONS_DIR.join("options.yml"))

    BUILD_DATE   = Time.now.strftime("%Y%m%d%H%M%S")
    GEM_HOME     = BUILD_DIR.join("#{OPTIONS.product_name}-gemset-#{OPTIONS.rpm.version}")
  end
end
