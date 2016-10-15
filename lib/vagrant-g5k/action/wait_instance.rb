module VagrantPlugins
  module G5K
    module Action
      class WaitInstance
        def initialize(app, env)
          @app = app
        end

        def call(env)
          job_id = env[:machine].id
          conn = env[:g5k_connection]
          conn.wait_for(job_id, env)
          @app.call(env)
        end
      end
    end
  end
end
