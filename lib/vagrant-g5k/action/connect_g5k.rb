require "log4r"
require "vagrant-g5k/util/g5k_utils"

module VagrantPlugins
  module G5K
    module Action
      # This action connects to G5K, verifies credentials work, and
      # puts the G5K connection object into the `:g5k_connection` key
      # in the environment.
      class ConnectG5K
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_g5k::action::connect_g5k")
        end

        def call(env)
          # This is a hack to make the connection persistent
          # even after environment unload is called
          if Connection.instance.nil?
            @logger.debug("Creating new connection")
            env[:g5k_connection] = Connection.new(env)
          else
            @logger.debug("Reusing connection")
            env[:g5k_connection] = Connection.instance
          end

          @app.call(env)
        end
      end
    end
  end
end
