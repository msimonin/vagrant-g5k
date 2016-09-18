module VagrantPlugins
  module G5K
    module Action
      # This can be used with "Call" built-in to check if the machine
      # is created and branch in the middleware.
      class IsCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          state_id = env[:machine].state.id
          env[:result] = state_id == :Running and state_id == :shutdown
          @app.call(env)
        end
      end
    end
  end
end
