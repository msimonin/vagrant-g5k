require "vagrant"

module VagrantPlugins
  module G5K
    module Errors
      class VagrantG5KError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_g5k.errors")
      end

      class TimeoutOnJobSubmissionError < VagrantG5KError
        error_key("tired of waiting")
      end

      class JobNotRunning < VagrantG5KError
        error_key("tired of waiting")
      end
    end
  end
end
