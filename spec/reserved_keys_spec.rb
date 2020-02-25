require 'i18nliner/reserved_keys'

describe I18n do
  it "adds new reserved keys" do
    expect(I18n::RESERVED_KEYS).to include(:i18nliner_scope)
    expect(I18n::RESERVED_KEYS).to include(:i18nliner_inferred_key)
  end
end
