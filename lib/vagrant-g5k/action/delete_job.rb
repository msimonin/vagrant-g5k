module VagrantPlugins
  module G5K
    module Action
      class DeleteJob
        def initialize(app, env)
          @app = app
        end

        def call(env)
          job_id = env[:machine].id
          conn = env[:g5k_connection]
          conn.exec("oardel #{job_id}")
          @app.call(env)
        end
      end
    end
  end
end
