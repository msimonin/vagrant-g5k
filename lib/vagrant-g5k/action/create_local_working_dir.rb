require "log4r"
require 'json'
require 'yaml'


module VagrantPlugins
  module G5K
    module Action
      # This runs the configured instance.
      class CreateLocalWorkingDir

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_g5k::action::run_instance")
        end

        def call(env)
          conn = env[:g5k_connection]
          conn.create_local_working_dir()
          @app.call(env)
        end

      end
    end
  end
end

