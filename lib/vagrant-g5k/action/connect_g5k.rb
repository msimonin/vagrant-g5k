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
          env[:g5k_connection] = Connection.new(
             :logger => env[:ui],
             :username => env[:machine].provider_config.username,
             :private_key => env[:machine].provider_config.private_key,
             :image_location => env[:machine].provider_config.image_location, 
             :site => env[:machine].provider_config.site,
             :ports => env[:machine].provider_config.ports,
             :backing_strategy => env[:machine].provider_config.backing_strategy
          )
          @app.call(env)
        end
      end
    end
  end
end
