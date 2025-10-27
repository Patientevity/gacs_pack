# frozen_string_literal: true

RSpec.describe GacsPack do
  it "has a version number" do
    expect(GacsPack::VERSION).not_to be nil
  end

  it "provides a logo_path" do
    expect(GacsPack.logo_path).to be_a(String)
    expect(GacsPack.logo_path).to end_with("gacso.png")
  end

  it "provides configuration interface" do
    expect(GacsPack).to respond_to(:configure)
    expect(GacsPack).to respond_to(:config)
    expect(GacsPack).to respond_to(:build)
  end
end
