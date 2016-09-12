module VagrantPlugins
  module G5K
    module Action
      class MessageAlreadyCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info("vagrant_g5k.already_status", :status => "created")
          @app.call(env)
        end
      end
    end
  end
end
