
module HelperCoerceBoolean
    def self.from_boolean value
        (value ? :true : :false) unless value.nil?
    end

    def self.to_boolean value
        case value
        when :true
            true
        when :false
            false
        end
    end
end

