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
          puts 'connect_g5k'
          env[:g5k_connection] = Connection.new(
             :logger => env[:ui],
             :username => env[:machine].provider_config.username,
             :image_location => env[:machine].provider_config.image_location, 
             :site => env[:machine].provider_config.site
          )
          @app.call(env)
        end
      end
    end
  end
end
