require 'i18n'
require 'i18nliner/base'

require 'i18nliner/extensions/core'
I18n.send :extend, I18nliner::Extensions::Core
I18n::RESERVED_KEYS << :i18n_scope

require 'i18nliner/railtie' if defined?(Rails)
