require "log4r"
require 'json'
require 'yaml'


module VagrantPlugins
  module G5K
    module Action
      # This runs the configured instance.
      class RunInstance
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_g5k::action::run_instance")
        end

        def call(env)
          conn = env[:g5k_connection]
          conn.launch_vm(env)
          @app.call(env)
        end

        def recover(env)
          return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)

          if env[:machine].provider.state.id != :not_created
            # Undo the import
            terminate(env)
          end
        end

      end
    end
  end
end

