module VagrantPlugins
  module G5K
    module Action
      class MessageNotCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info("vagrant_g5k.not_created")
          @app.call(env)
        end
      end
    end
  end
end
