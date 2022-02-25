
# Just a helper function
module HelperRandomPassword
    def self.random_password length = 15
        (('A'..'Z').to_a.shuffle[0,1] + ('a'..'z').to_a.shuffle[0,length-2] + ('0'..'9').to_a.shuffle[0,1]).shuffle.join
    end
end

