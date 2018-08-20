
class IPMI
    class <<self
        def debug *args
            # FIXME
            Puppet::Util::Log.create({ level: :warning, source: 'Lib[ipmi]', message: args.join(' ') })
        end

        #
        #  Parser functions
        #

        def key_to_sym key
            key.downcase.tr(' ', '_').to_sym
        end

        def parse_colon_tuples data
            value_list = []
            data.lines.map(&:strip).map do |line|
                key, value = line.split /\s*:\s*/, 2
                unless key.nil? or key.empty?
                    value_list = [ value ]
                    [ IPMI.key_to_sym(key), value_list ]
                else
                    value_list << value
                    nil
                end
            end.compact.to_h
        end

        def parse_sectioned_colon_tuples data
            data.to_s.split(/\n\n/).map { |info| IPMI.parse_colon_tuples info }
        end

        def parse_csv data, labels
            data.lines.map do |line|
                [ labels, line.split(',') ].transpose.to_h
            end
        end

        #
        #  Command
        #

        # This is kinda ugly, we provide ipmitoolcmd ipmlementation outside
        attr_accessor :ipmitoolcmd

        def ipmitool args, type = :tuples, labels = nil
            @cache ||= {}
            commandline = "ipmitool #{args.join ' '}"
            @cache[commandline] ||=
                begin
                    IPMI.debug "running: #{commandline}"
                    text = IPMI.ipmitoolcmd.call args
                    case type
                    when :multi_tuples
                        IPMI.parse_sectioned_colon_tuples text
                    when :tuples
                        IPMI.parse_colon_tuples text
                    when :csv
                        IPMI.parse_csv text, labels
                    when :plain
                        text
                    end
                end
        end

        #
        #  Global system state objects
        #

        def detect_lan_cid
            # we're optimizing here, since LAN channel usually have ID 1
            [ 1, 0, *(2..12), 15 ].find do |cid|
                IPMI.ipmitool(['channel', 'info', cid], :tuples).fetch(:channel_medium_type, []).first == '802.3 LAN'
            end
        end

        def lan cid = IPMI.detect_lan_cid
            @lan||= {}
            @lan[cid] ||= IPMI::LAN.new cid
        end

        def sol cid = IPMI.detect_lan_cid
            @sol||= {}
            @sol[cid] ||= IPMI::SOL.new cid
        end

        def users cid = IPMI.detect_lan_cid
            @users||= {}
            @users[cid] ||= IPMI::Users.new cid
        end
    end
end

class IPMI
    class LAN
        class <<self
            def to_ipsrc value
                case value
                when 'Static Address'
                    :static
                when 'DHCP Address'
                    :dhcp
                else
                    # XXX :none, :bios
                    value
                end
            end

            def to_priv value
                case value
                when 'a'
                    :admin
                when 'o'
                    :operator
                when 'u'
                    :user
                when 'c'
                    :callback
                when 'O'
                    :oem
                when 'X'
                    :no_access
                else
                    value
                end
            end

            def from_priv value
                case value
                when :admin
                    'a'
                when :operator
                    'o'
                when :user
                    'u'
                when :callback
                    'c'
                when :oem
                    'O'
                when :no_access
                    'X'
                else
                    value
                end
            end
        end

        attr_reader :cid

        def initialize cid
            @cid = cid
        end

        def get_all field
            IPMI.ipmitool(['lan', 'print', cid], :tuples).fetch(field, [])
        end

        def get field
            get_all(field).first
        end

        def set field, value
            IPMI.ipmitool(['lan', 'set', cid, field.to_s.split, value], :plain)
        end

        #
        #  Fields
        #

        def auth
            IPMI.parse_colon_tuples(get_all(:auth_type_enable).join("\n")).map { |who, what| [ who, what.first.split(' ').map(&:downcase).map(&:to_sym) ] }.to_h
        end

        def auth= value
            value.each do |who, what|
                set "auth #{who}", what.join(',')
            end
        end

        def ipaddr
            get :ip_address
        end

        def ipaddr= value
            set :ipaddr, value
        end

        def netmask
            get :subnet_mask
        end

        def netmask= value
            set :netmask, value
        end

        def defgw_ipaddr
            get :default_gateway_ip
        end

        def defgw_ipaddr= value
            set 'defgw ipaddr', value
        end

        def bakgw_ipaddr
            get :backup_gateway_ip
        end

        def bakgw_ipaddr= value
            set 'bakgw ipaddr', value
        end

        def ipsrc
            LAN.to_ipsrc(get(:ip_address_source))
        end

        def ipsrc= value
            set :ipsrc, value
        end

        def snmp
            get :snmp_community_string
        end

        def snmp= value
            set :snmp, value
        end

        def arp_respond
            get(:bmc_arp_control).split(/,\s*/).include? 'ARP Responses Enabled'
        end

        def arp_respond= value
            set 'arp respond', value ? 'on' : 'off'
        end

        def arp_generate
            get(:bmc_arp_control).split(/,\s*/).include? 'Gratuitous ARP Enabled'
        end

        def arp_generate= value
            set 'arp generate', value ? 'on' : 'off'
        end

        def cipher_privs
            get(:cipher_suite_priv_max).split('').map { |priv| LAN.to_priv priv }
        end

        def cipher_privs= value
            set :cipher_privs, value.map { |priv| LAN.from_priv priv }.join('')
        end
    end
end

class IPMI
    class SOL
        attr_reader :cid

        def initialize cid
            @cid = cid
        end

        def get field
            IPMI.ipmitool(['sol', 'info', cid, '-c'], :csv, [
                :set_in_progress, :enabled, :force_encryption, :force_authentication,
                :privilege_level, :character_accumulate_level, :character_send_threshold,
                :retry_count, :retry_interval, :volatile_bit_rate, :non_volatile_bit_rate,
                :payload_channel, :payload_port
            ]).first.fetch(field, [])
        end

        def set field, value
            IPMI.ipmitool(['sol', 'set', field.to_s.tr('_', '-'), value, cid], :plain)
        end

        #
        #  Fields
        #

        def enabled
            get(:enabled) == 'true'
        end

        def enabled= value
            set :enabled, value.to_s
        end

        def force_encryption
            get(:force_encryption) == 'true'
        end

        def force_encryption= value
            set :force_encryption, value.to_s
        end

        def force_authentication
            get(:force_authentication) == 'true'
        end

        def force_authentication= value
            set :force_authentication, value.to_s
        end
    end
end

class IPMI
    class User
        class <<self
            def to_priv value
                case value
                when 'ADMINISTRATOR'
                    :admin
                when 'OPERATOR'
                    :operator
                when 'USER'
                    :user
                when 'OEM'
                    :oem
                when 'CALLBACK'
                    :callback
                when 'Unknown (0x00)'
                    :no_access
                else
                    value
                end
            end

            def from_priv value
                case value
                when :admin
                    4
                when :operator
                    3
                when :user
                    2
                when :callback
                    1
                when :oem
                    5
                when :no_access
                    15
                else
                    value
                end
            end
        end

        attr_reader :cid, :data

        def initialize cid, data
            @cid  = cid
            @data = data
        end

        def get field
            data.fetch(field, []).first
        end

        def set field, value
            IPMI.ipmitool(['channel', 'setaccess', cid, uid, "#{field}=#{value}"], :plain)
        end

        #
        #  Fields
        #

        # read-only property
        def uid
            get(:user_id).to_i
        end

        def name
            get :user_name
        end

        def name= value
            IPMI.ipmitool(['user', 'set', 'name', uid, value], :plain)
        end

        # read-only property
        def fixed_name
            get(:fixed_name) == 'Yes'
        end

        # no getter method, we can only check if provided password matches the stored value
        def password? value
            IPMI.ipmitool(['user', 'test', uid, '16', value], :plain)
        end

        def password= value
            IPMI.ipmitool(['user', 'set', 'password', uid, value], :plain)
        end

        def callin
            get(:access_available).split(/\s*\/\s*/).include? 'call-in'
        end

        def callin= value
            set :callin, value ? 'on' : 'off'
        end

        def ipmi
            get(:ipmi_messaging) == 'enabled'
        end

        def ipmi= value
            set :ipmi, value ? 'on' : 'off'
        end

        def link
            get(:link_authentication) == 'enabled'
        end

        def link= value
            set :link, value ? 'on' : 'off'
        end

        def privilege
            # XXX this does not take into account 'user priv'
            User.to_priv get :privilege_level
        end

        def privilege= value
            set :privilege, USER.from_priv(value)
        end

        def enabled
            # XXX may be missing in output
            get(:enable_status) == 'enabled'
        end

        def enabled= value
            IPMI.ipmitool(['user', value ? 'enable' : 'disable', uid], :plain)
        end

        def sol
            IPMI.ipmitool(['sol', 'payload', 'status', cid, uid], :plain).end_with? 'enabled'
        end

        def sol= value
            IPMI.ipmitool(['sol', 'payload', value ? 'enable' : 'disable', cid, uid], :plain)
        end
    end

    class Users
        attr_reader :cid

        def initialize cid
            @cid  = cid
            @user = []
        end

        def get field
            IPMI.ipmitool(['channel', 'getaccess', cid], :multi_tuples).first.fetch(field, []).first
        end

        def maximum_users
            get(:maximum_user_ids).to_i
        end

        def enabled_users
            get(:enabled_user_ids).to_i
        end

        def user uid
            @user[uid] ||= User.new(cid, IPMI.ipmitool(['channel', 'getaccess', cid], :multi_tuples)[uid])
        end
    end
end

# the end
