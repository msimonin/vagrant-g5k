module VagrantPlugins
  module G5K
    module Action
      class MessageNotRunning
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info("vagrant_g5k.not_running")
          @app.call(env)
        end
      end
    end
  end
end
