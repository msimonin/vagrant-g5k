require "log4r"

module VagrantPlugins
  module G5K
    module Action
      # This action reads the state of the machine and puts it in the
      # `:machine_state_id` key in the environment.
      class ReadState
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_g5k::action::read_state")
        end

        def call(env)
          env[:machine_state_id] = read_state(env)
          @app.call(env)
        end

        def read_state(env)
          machine = env[:machine]
          conn = env[:g5k_connection]
          id = machine.id
          local_storage = conn.check_storage(env)
          if id.nil? and local_storage.nil?
            return :not_created
          end

          if id.nil? and not local_storage.nil?
            return :shutdown
          end
         
          if not id.nil?
            # is there a job running for this vm ?
            job = conn.check_job(id)
            if job.nil?
              return :not_created
            end
            
            net_state = conn.check_net(id)
            return net_state.to_sym unless net_state.nil?

            return job["state"].to_sym
          end

            return :guru_meditation
        end
      end
    end
  end
end
