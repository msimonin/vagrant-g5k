require "log4r"
require "vagrant-g5k/util/g5k_utils"

# Unused
module VagrantPlugins
  module G5K
    module Action
      # This action connects to G5K, verifies credentials work, and
      # puts the G5K connection object into the `:g5k_connection` key
      # in the environment.
      class CloseG5K
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_g5k::action::close_g5k")
        end

        def call(env)
          env[:g5k_connection].close()
          @app.call(env)
        end
      end
    end
  end
end
