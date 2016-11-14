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
          username = env[:machine].provider_config.username
          gateway = env[:machine].provider_config.gateway
          if !env[:machine].provider_config.gateway.nil?
            ssh_info[:proxy_command] = "ssh #{username}@#{gateway} #{ssh_key(env)} nc %h %p"
          end
          env[:machine_ssh_info] = ssh_info

          @app.call(env)
        end

        def ssh_key(env)
          private_key = env[:machine].provider_config.private_key
          if private_key.nil?
            ""
          else
             "-i #{private_key}"
          end
        end
      
      end
    end
  end
end
