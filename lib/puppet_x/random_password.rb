
# Just a helper function
module HelperRandomPassword
    def self.random_password length = 15
        ('a'..'z').to_a.shuffle[0,length].join
    end
end

