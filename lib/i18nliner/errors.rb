module I18nliner
  class ExtractionError < StandardError
    def initialize(line, detail = nil)
      @line = line
      @detail = detail
    end

    def to_s
      error = self.class.name.underscore.humanize
      error.gsub!(/\AI18nliner\/| error\z/, '')
      error = "#{error} on line #{@line}"
      @detail ?
        error + " (got #{@detail.inspect})" :
        error
    end
  end

  # extraction errors
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

  # pre-processing errors
  class TBlockNestingError < StandardError; end
  class MalformedErbError < StandardError; end
  class UnwrappableContentError < StandardError; end

  # runtime errors
  class InvalidBlockUsageError < ArgumentError; end
end
