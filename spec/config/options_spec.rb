RSpec.describe "options.yml" do
  options = ManageIQ::RPMBuild::OPTIONS
  major_version = options.rpm.version.split(".").first
  name_version = options.rpm_repository.content.keys.first.to_s.split("-")[0..1].join("-")

  nightly_versions = [
    "#{major_version}.1.0-20211208000053",
    "#{major_version}.1.0-20211209000053",
  ]

  release_versions = [
    "#{major_version}.1.0-alpha1",
    "#{major_version}.1.1-beta1",
    "#{major_version}.1.2-rc1",
    "#{major_version}.1.3-rc2",
    "#{major_version}.1.4-1",
    "#{major_version}.1.4-1.1",
    "#{major_version}.1.5-1",
    "#{major_version}.2.1-1",
  ]

  suffixes = [
    nil, # For manageiq
    "appliance",
    "appliance-tools",
    "core",
    "gemset",
    "pods",
    "system",
    "ui",
  ]

  shared_examples "expect_included_rpm" do |file, rpm|
    it("includes #{file}") { expect(file).to match(options.rpm_repository.content[repo].rpms[rpm]) }
  end

  shared_examples "expect_excluded_rpm" do |file, rpm|
    it("excludes #{file}") { expect(file).not_to match(options.rpm_repository.content[repo].rpms[rpm]) }
  end

  describe "nightly repo" do
    let(:repo) { "#{name_version}-nightly" }
    context "manageiq rpms" do
      suffixes.each do |suffix|
        release_versions.each do |version|
          file = ["manageiq", suffix, version].compact.join("-") + ".el9.x86_64.rpm"
          include_examples("expect_excluded_rpm", file, "manageiq-nightly")
        end

        nightly_versions.each do |version|
          file = ["manageiq", suffix, version].compact.join("-") + ".el9.x86_64.rpm"
          include_examples("expect_included_rpm", file, "manageiq-nightly")
        end
      end
    end
  end

  describe "release repo" do
    let(:repo) { name_version }
    context "manageiq-release rpms" do
      [
        "manageiq-release-#{major_version}.0-1.el9.noarch.rpm",
        "manageiq-release-#{major_version}.0-2.el9.noarch.rpm",
      ].each { |file| include_examples("expect_included_rpm", file, "manageiq-release") }
    end

    context "manageiq rpms" do
      suffixes.each do |suffix|
        release_versions.each do |version|
          file = ["manageiq", suffix, version].compact.join("-") + ".el9.x86_64.rpm"
          include_examples("expect_included_rpm", file, "manageiq")
        end

        nightly_versions.each do |version|
          file = ["manageiq", suffix, version].compact.join("-") + ".el9.x86_64.rpm"
          include_examples("expect_excluded_rpm", file, "manageiq")
        end
      end
    end
  end
end
