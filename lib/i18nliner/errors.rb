module I18nliner
  class ExtractionError < StandardError
    def initialize(line, detail = nil)
      @line = line
      @detail = detail
    end

    def to_s
      error = self.class.name.humanize.sub(/ error\z/, '')
      error = "#{error} on line #{@line}"
      @detail ?
        error + " (got #{@detail.inspect})" :
        error
    end
  end

  class InvalidSignatureError < ExtractionError; end
  class MissingDefaultError < ExtractionError; end
  class AmbiguousKeyError < ExtractionError; end
  class InvalidPluralizationKeyError < ExtractionError; end
  class MissingPluralizationKeyError < ExtractionError; end
  class InvalidPluralizationDefaultError < ExtractionError; end
  class MissingCountValueError < ExtractionError; end
  class MissingInterpolationValueError < ExtractionError; end
  class InvalidOptionsError < ExtractionError; end
  class InvalidOptionKeyError < ExtractionError; end
  class KeyAsScopeError < ExtractionError; end
  class KeyInUseError < ExtractionError; end
end
