RSpec.describe(ManageIQ::RPMBuild::NightlyBuildPurger) do
  it("#package_timestamp_from_key (private)") do
    expect(described_class.new.send(:package_timestamp_from_key, "builds/manageiq-nightly/manageiq-pods-13.0.0-20211004000013.el8.x86_64.rpm")).to eq(["manageiq-pods-13.0.0", "20211004000013"])
    expect(described_class.new.send(:package_timestamp_from_key, "builds/manageiq-nightly/manageiq-ui-13.0.0-20211004000013.el8.x86_64.rpm")).to eq(["manageiq-ui-13.0.0", "20211004000013"])
    expect(described_class.new.send(:package_timestamp_from_key, "builds/manageiq-nightly/manageiq-ui-13.0.0-0.1.20210705000025.el8.x86_64.rpm")).to eq(["manageiq-ui-13.0.0", "20210705000025"])
  end

  it("#recent? (private)") do
    allow(subject).to receive(:now).and_return(Time.at(1668100000).utc) # 2022-11-10 17:06:40

    expect(subject.send(:recent?, "20221110170640")).to eq(true) # Now
    expect(subject.send(:recent?, "20221230170640")).to eq(true) # Future
    expect(subject.send(:recent?, "20221104170640")).to eq(true) # 6 days ago
    expect(subject.send(:recent?, "20221103170640")).to eq(false) # 1 week ago
    expect(subject.send(:recent?, "20221027170640")).to eq(false) # 2 weeks ago
    expect(subject.send(:recent?, "19700101000000")).to eq(false)
    expect { subject.send(:recent?, "xyz") }.to raise_error(Date::Error)
  end
end
