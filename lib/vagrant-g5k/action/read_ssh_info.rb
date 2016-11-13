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
          conn = env[:g5k_connection]
          ssh_info = conn.vm_ssh_info(env[:machine].id)
          if !conn.gateway.nil?
            ssh_info[:proxy_command] = "ssh #{conn.username}@#{conn.gateway} #{ssh_key(conn)} nc %h %p"
          end
          env[:machine_ssh_info] = ssh_info

          @app.call(env)
        end

        def ssh_key(conn)
          if conn.private_key.nil?
            ""
          else
             "-i #{conn.private_key}"
          end
        end
      
      end
    end
  end
end
