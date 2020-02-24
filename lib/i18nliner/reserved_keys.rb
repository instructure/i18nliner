keys = I18n::RESERVED_KEYS.dup
keys << :i18nliner_scope << :i18nliner_inferred_key
I18n.send(:remove_const, :RESERVED_KEYS)
I18n.const_set(:RESERVED_KEYS, keys)
