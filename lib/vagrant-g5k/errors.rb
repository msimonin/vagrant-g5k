require "vagrant"

module VagrantPlugins
  module G5K
    module Errors
      class VagrantG5KError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_g5k.errors")
      end

      class TimeoutOnJobSubmissionError < VagrantG5KError
        error_key("tired_of_waiting")
      end

      class JobNotRunning < VagrantG5KError
        error_key("tired_of_waiting")
      end

      class JobError < VagrantG5KError
        error_key("job_error")
      end


      class CommandError < VagrantG5KError
        error_key("remote_command_error")
      end


    end
  end
end
