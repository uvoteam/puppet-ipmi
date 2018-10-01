
require 'puppet/util'
require 'puppet/util/execution'

#
#  Container class without instance
#

class IPMI
    class <<self
        def debug *args
            Puppet::Util::Log.create({ level: :debug, source: 'Lib[ipmi]', message: args.join(' ') })
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

        def ipmitool args, options = {}
            @cache ||= {}
            commandline = "ipmitool #{args.join ' '}"
            @cache[commandline] ||=
                begin
                    IPMI.debug "running: #{commandline}"
                    begin
                        # XXX this is supposedly protected by provider's 'command' constraint
                        text = Puppet::Util::Execution.execute([Puppet::Util.which('ipmitool')] + args, {
                            failonfail: (not options[:can_fail]),
                            combine:    (not options[:drop_stderr]),
                        })
                    rescue Exception => e
                        @cache[commandline] = e.message
                        raise
                    end
                    case options[:type]
                    when :multi_tuples
                        IPMI.parse_sectioned_colon_tuples text
                    when :tuples, nil
                        IPMI.parse_colon_tuples text
                    when :csv
                        IPMI.parse_csv text, options[:labels]
                    when :plain
                        text
                    end
                end
        end

        #
        #  Global system state objects
        #

        def version
            Gem::Version.new(IPMI.ipmitool(['mc', 'info']).fetch(:impi_version).first)
        end

        def has_ipmi_2?
            IPMI.version.segments.first >= 2
        end

        def lan_cids
            [*(0..11), 15]
                .select do |cid|
                    # there's no way to detect which channels exist, thus we're ignoring ipmitool fails on absent ones
                    IPMI.ipmitool(['channel', 'info', ('0x%x' % cid)], { can_fail: true }).fetch(:channel_medium_type, []).first == '802.3 LAN'
                end
        end

        def lan_channels
            lan_cids.map { |cid| IPMI.lan cid }
        end

        def lan cid = IPMI.lan_channels.first.cid
            @lan||= {}
            @lan[cid] ||= IPMI::LAN.new cid
        end

        # XXX maybe make 'users' a lan accessor
        def users cid = IPMI.lan.cid
            @users||= {}
            @users[cid] ||= IPMI::Users.new cid
        end
    end
end

#
#  Channel instance
#

class IPMI
    class LAN
        class SOL
            attr_reader :cid

            def initialize cid
                @cid = cid
            end

            def get field
                # information messages may clutter output and confuse the parser, thus we're dropping stderr
                IPMI.ipmitool(['sol', 'info', cid, '-c'], { drop_stderr: true, type: :csv, labels: [
                    :set_in_progress, :enabled, :force_encryption, :force_authentication,
                    :privilege_level, :character_accumulate_level, :character_send_threshold,
                    :retry_count, :retry_interval, :volatile_bit_rate, :non_volatile_bit_rate,
                    :payload_channel, :payload_port
                ]}).first.fetch(field, [])
            end

            def set field, value
                IPMI.ipmitool(['sol', 'set', field.to_s.tr('_', '-'), value, cid], { type: :plain })
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
            IPMI.ipmitool(['lan', 'print', cid]).fetch(field, [])
        end

        def get field
            get_all(field).first
        end

        def set field, value
            IPMI.ipmitool(['lan', 'set', cid, field.to_s.split, value], { type: :plain })
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
            # this always returns 1 on supermicro boards
            begin
                set 'arp respond', value ? 'on' : 'off'
            rescue Puppet::ExecutionFailure => err
                unless / returned 1: (?:Enabling|Disabling) BMC-generated ARP responses\Z/ =~ err.message
                    raise
                end
            end
        end

        def arp_generate
            get(:bmc_arp_control).split(/,\s*/).include? 'Gratuitous ARP Enabled'
        end

        def arp_generate= value
            # this always returns 1 on supermicro borads
            begin
                set 'arp generate', value ? 'on' : 'off'
            rescue Puppet::ExecutionFailure => err
                unless / returned 1: (?:Enabling|Disabling) BMC-generated Gratuitous ARPs\Z/ =~ err.message
                    raise
                end
            end
        end

        def cipher_privs
            get(:cipher_suite_priv_max).split('').map { |priv| LAN.to_priv priv }
        end

        def cipher_privs= value
            set :cipher_privs, value.map { |priv| LAN.from_priv priv }.join('')
        end

        def sol
            @sol ||= SOL.new cid
        end
    end
end

#
#  Users instance/container
#

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
                when 'Unknown (0x00)', 'NO ACCESS'
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
            IPMI.ipmitool(['channel', 'setaccess', cid, uid, "#{field}=#{value}"], { type: :plain })
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
            IPMI.ipmitool(['user', 'set', 'name', uid, value], { type: :plain })
        end

        # read-only property
        def fixed_name
            get(:fixed_name) == 'Yes'
        end

        # no getter method, we can only check if provided password matches the stored value
        def password? value, length = 16
            IPMI.ipmitool(['user', 'test', uid, length, value], { type: :plain })
        end

        def password= args
            value, length = args.is_a?(Array) ? args : [args, 16]
            IPMI.ipmitool(['user', 'set', 'password', uid, value, length], { type: :plain })
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
            set :privilege, User.from_priv(value)
        end

        def enabled
            # XXX this field will be missing in output with ipmitool < 1.8.18
            if get(:enable_status) == 'unknown'
                # on Dell iDRAC 6 this field is 'unknown', but user enable/disable operotion switches link&ipmi simultaneously
                link and ipmi
            else
                get(:enable_status) == 'enabled'
            end
        end

        def enabled= value
            IPMI.ipmitool(['user', value ? 'enable' : 'disable', uid], { type: :plain })
        end

        def sol
            begin
                IPMI.ipmitool(['sol', 'payload', 'status', cid, uid], { type: :plain }).strip.end_with? 'enabled'
            rescue
                # this command can fail on RMM3 when user have not been created yet
                unless privilege == :no_access
                    raise
                end
                false
            end
        end

        def sol= value
            IPMI.ipmitool(['sol', 'payload', value ? 'enable' : 'disable', cid, uid], { type: :plain })
        end
    end

    class Users
        attr_reader :cid

        def initialize cid
            @cid  = cid
            @user = []
        end

        def get field
            IPMI.ipmitool(['channel', 'getaccess', cid], { type: :multi_tuples }).first.fetch(field, []).first
        end

        def maximum_users
            get(:maximum_user_ids).to_i
        end

        def enabled_users
            get(:enabled_user_ids).to_i
        end

        def user uid
            @user[uid] ||= User.new(cid, IPMI.ipmitool(['channel', 'getaccess', cid], { type: :multi_tuples })[uid])
        end

        # XXX
        def each &block
            (1..maximum_users).map { |uid| user uid }.each &block
        end

        def map &block
            (1..maximum_users).map { |uid| user uid }.map &block
        end
    end
end

# the end
