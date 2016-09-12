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
          env[:machine_ssh_info] = read_ssh_info(env[:g5k_connection], env[:machine])

          @app.call(env)
        end

        def read_ssh_info(conn, machine)
          return nil if machine.id.nil?

          return { :host          => conn.ip,
                   :proxy_command => "ssh #{conn.username}@access.grid5000.fr nc %h %p",
}
        end
      end
    end
  end
end
