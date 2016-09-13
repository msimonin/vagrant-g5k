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
          env[:machine_state_id] = read_state(env[:machine], env[:g5k_connection])
          @app.call(env)
        end

        def read_state(machine, conn)
          return :not_created if machine.id.nil?
          # is there a job running for this vm ?
          job = conn.check_job(machine.id)
          if job.nil? # TODO or fraged
            return :not_created
          end

          return job["state"].to_sym
        end
      end
    end
  end
end
