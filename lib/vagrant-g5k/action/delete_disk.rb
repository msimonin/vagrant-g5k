module VagrantPlugins
  module G5K
    module Action
      class DeleteDisk
        def initialize(app, env)
          @app = app
        end

        def call(env)
          conn = env[:g5k_connection]
          env[:ui].info("Deleting the associated disk")
          conn.delete_disk(env)
          @app.call(env)
        end
      end
    end
  end
end
