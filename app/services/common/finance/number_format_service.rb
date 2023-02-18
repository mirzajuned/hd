class Common::Finance::NumberFormatService
	class << self
		def call(number_format, value_to_convert)
			if number_format == 1
				ActiveSupport::NumberHelper::number_to_delimited("#{value_to_convert}") # Western Format 12,345,678.99
			elsif number_format == 2
				ActiveSupport::NumberHelper::number_to_delimited("#{value_to_convert}", delimiter_pattern: /(\d+?)(?=(\d\d)+(\d)(?!\d))/) # Indian Format 1,23,45,678.99
			else
				return "#{value_to_convert}"
			end	
		end
	end
end
