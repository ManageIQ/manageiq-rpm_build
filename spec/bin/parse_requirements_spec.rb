require_relative "../../bin/parse_requirements"

RSpec.describe ParseRequirements do
  # tests just assume there is one python rpm installed
  before { subject.os_packages = %w[paramiko] }

  describe "#parse_line" do
    it "ignores blanks" do
      expect(parse_line("")).to be_nil
      expect(parse_line("# comment")).to be_nil
    end

    it "parses non versions" do
      expect(parse_line("a")).to eq(["a", ""])
      expect(parse_line("paramiko")).to eq(["paramiko", ""])
    end

    it "parses versions" do
      expect(parse_line("a >= 5")).to eq(["a", ">=5"])
      expect(parse_line("b>= 5")).to eq(["b", ">=5"])
    end

    it "respects rpm libraries" do
      expect(parse_line("a >= 5")).to eq(["a", ">=5"])
      expect(parse_line("paramiko>= 5")).to eq(["paramiko", ""])
    end

    it "convert == to >=" do
      expect(parse_line("a == 5")).to eq(["a", ">=5"])
    end
  end

  describe "#consolidate_vers" do
    it "picks the higher comparison" do
      expect(subject).to receive(:warn).with("b: >2 > >1")
      expect(consolidate_vers({">1" => ["c1"], ">2" => ["legacy"]}, :lib => "b")).to eq([">2", ["c1"]])
    end
  end

  def parse_line(line)
    subject.send(:parse_line, line)
  end

  def consolidate_vers(vers, lib: nil)
    subject.send(:consolidate_vers, vers, :lib => lib)
  end
end
