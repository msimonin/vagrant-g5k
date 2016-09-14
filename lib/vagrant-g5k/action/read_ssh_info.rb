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
          ports = env[:machine].provider_config.ports
          ssh_fwd = ports.select{ |x| x.split(':')[1] == '22'}.first
          if ssh_fwd.nil?
            env[:ui].error "SSH port 22 must be forwarded"
            raise Error "SSh port 22 isn't forwarded"
          end
          ssh_fwd = ssh_fwd.split('-:')[0]
          env[:machine_ssh_info] = read_ssh_info(env[:g5k_connection], env[:machine], ssh_fwd)

          @app.call(env)
        end

        def read_ssh_info(conn, machine, ssh_fwd)
          return nil if machine.id.nil?

          if ssh_fwd.nil? 

            raise Error "ssh_port should be forwarded"
          end

          return { :host          => conn.node,
                   :port          => ssh_fwd,
                   :proxy_command => "ssh #{conn.username}@access.grid5000.fr nc %h %p",
}
        end
      end
    end
  end
end
