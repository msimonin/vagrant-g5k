require "log4r"

module VagrantPlugins
  module G5K
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_g5k::action::read_ssh_info")
        end

        def call(env)
          net = env[:machine].provider_config.net
          # Note: better to encapsulate this in a NetDriver
          if net["type"] == 'bridge'
            env[:machine_ssh_info] = read_ssh_info(env[:g5k_connection], env[:machine])
          else
            ports = net["ports"]
            ssh_fwd = ports.select{ |x| x.split(':')[1] == '22'}.first
            if ssh_fwd.nil?
              env[:ui].error "SSH port 22 must be forwarded"
              raise Error "SSh port 22 isn't forwarded"
            end
            ssh_fwd = ssh_fwd.split('-:')[0]
            env[:machine_ssh_info] = read_ssh_info(env[:g5k_connection], env[:machine], ssh_fwd)
          end
          @app.call(env)
        end

        def ssh_key(conn)
          if conn.private_key.nil?
            ""
          else
             "-i #{conn.private_key}"
          end
        end


        def read_ssh_info(conn, machine, ssh_fwd = nil)
          return nil if machine.id.nil?

          ssh_info = {
                   :host          => conn.node,
          }

          ssh_info[:port] = ssh_fwd unless ssh_fwd.nil?

          if !conn.gateway.nil?
            ssh_info[:proxy_command] = "ssh #{conn.username}@#{conn.gateway} #{ssh_key(conn)} nc %h %p"
          end
          return ssh_info
        end
      end
    end
  end
end
