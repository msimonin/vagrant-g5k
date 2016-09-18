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
          args = {
            :@ui => env[:ui]
          }
          a =  env[:machine].provider_config.instance_variables.map do |attr|
            [ attr, env[:machine].provider_config.instance_variable_get(attr)]
          end.to_h
          args.merge!(a)
          #.map do |attr|
          #  {attr => env[:machine].provider_config.instance_variable_get(attr)}
          #end
          env[:g5k_connection] = Connection.new(
            args
          )
          @app.call(env)
        end
      end
    end
  end
end
