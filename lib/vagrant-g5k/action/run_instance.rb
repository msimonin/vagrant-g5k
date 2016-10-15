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
          # Note: here we are sure that we have to start the vm
          conn = env[:g5k_connection]
          conn.launch_vm(env)
          @app.call(env)
        end

        def recover(env)
          return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)

          if ![:not_created, :shutdown].include?(env[:machine].provider.state.id)
            # Undo the import
            terminate(env)
          end
        end

        def terminate(env)
         @logger.info("Terminate the machine")
        end

      end
    end
  end
end

