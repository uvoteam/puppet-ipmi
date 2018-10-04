
module HelperCoerceBoolean
    def self.from_boolean value
        value ? :true : :false
    end

    def self.to_boolean value
        value == :true
    end
end

