require 'log4r'

module VagrantPlugins
  module G5K
    class Oar
  
      include Vagrant::Util::Retryable

      attr_accessor :driver

      def initialize(ui, driver)
        @logger = Log4r::Logger.new("vagrant::environment")
        @driver = driver
        @ui = ui
      end
      
      def submit_job(cmd, options)
        # prefix by the oarsub command
        opt = _build_oar_cmd(options)
        # get the job id returned by the command
        extra = ["| grep \"job_id\"| cut -d':' -f2"]
        cmd = ["oarsub --json", opt,"\'#{cmd}\'" , extra].join(" ")
        @driver.exec(cmd).gsub(/"/,"").strip.to_i
      end

      def delete_job(job_id, options = [])
        cmd = _build_oar_cmd(options)
        cmd = ["oardel", cmd, job_id].join(" ")
        @driver.exec(cmd) 
      end

      def check_job(job_id)
        cmd = ['oarstat']
        cmd << "--json"
        cmd << "-j #{job_id}"
        cmd = cmd.join(" ")
        job = @driver.exec(cmd)
        JSON.load(job)["#{job_id}"]
      end

      def look_by_name(job_name)
        begin
          jobs = @driver.exec("oarstat -u --json")
          jobs = JSON.load(jobs)
          s = jobs.select{|k,v| v["name"] == "#{job_name}" }.values.first
          return s
        rescue Exception => e
          @logger.debug(e)
        end
        nil
      end
     
      def wait_for(job_id)
        job = nil
        begin
          retryable(:on => VagrantPlugins::G5K::Errors::JobNotRunning, :tries => 100, :sleep => 1) do
            job = check_job(job_id)
            if !job.nil? and ["Error", "Terminated"].include?(job["state"])
              process_errors(job_id)
            end
            if job.nil? or (!job.nil? and job["state"] != "Running")
              @ui.info("Waiting for the job to be running")
              raise VagrantPlugins::G5K::Errors::JobNotRunning 
            end
            break
          end
        rescue VagrantPlugins::G5K::Errors::JobNotRunning
          @ui.error("Tired of waiting")
          raise VagrantPlugins::G5K::Errors::JobNotRunning
        end
        return job
      end

      def _build_oar_cmd(options)
        options.join(" ")
      end

    end
  end
end

