
module HelperCoerceBoolean
    def from_boolean value
        value ? :true : :false
    end

    def to_boolean value
        value == :true
    end
end

