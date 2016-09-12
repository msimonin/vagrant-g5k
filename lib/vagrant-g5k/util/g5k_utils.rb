require 'net/ssh/multi'
require 'net/scp'
require 'json'

require 'vagrant/util/retryable'

WORKING_DIR = ".vagrant-g5k"
LAUNCHER_SCRIPT = "launch_vm.sh"
JOB_SUBNET_NAME = "vagrant-g5k-subnet"
WALLTIME="01:00:00"

module VagrantPlugins
  module G5K
    class Connection
      include Vagrant::Util::Retryable

      attr_accessor :session

      attr_accessor :username

      attr_accessor :site

      attr_accessor :image_location

      attr_accessor :logger

      attr_accessor :node
      
      attr_accessor :pool

      attr_accessor :ip

      attr_accessor :mac

      @@locations = [
        {
          :path => "/grid5000/virt-images",
          :type => "local"
        }
      ]

      def initialize(args)
        # initialize
        args.each do |k,v|
          instance_variable_set("@#{k}", v) unless v.nil?
        end

        gateway = Net::SSH::Gateway.new("access.grid5000.fr", "msimonin", :forward_agent => true)
        @session = gateway.ssh(@site, "msimonin")
      end

      def list_images()
        images = []
        @@locations.each do |location|
          if location[:type] == "local"
            stdout = ""
            @session.exec!("ls #{location[:path]}/*.qcow2") do |channel, stream, data| 
              stdout << data
            end
            images += stdout.split("\n").map{ |i| {:path => i, :type => 'local'} }
          #elsif location[:type] == "ceph"
          #  stdout = ""
          #  @session.exec!("rbd --pool #{location[:pool]} --conf $HOME/.ceph/config --id #{location[:id]} ls") do |channel, stream, data|
          #    stdout << data
          #  end
          #  images += stdout.split("\n").map{ |i| {:path => i, :type => 'ceph'} }
          end
        end
        images
      end
      
      def create_local_working_dir(env)
        @session.exec("mkdir -p #{WORKING_DIR}")
      end


      def check_job(job_id)
        oarstat = exec("oarstat --json")
        oarstat = JSON.load(oarstat)
        r = oarstat.select!{ |k,v| k == job_id and v["owner"] == @username }.values.first
        # update the assigned hostname
        # this will be used to reach the vm 
        if !r.nil?
          @node = r["assigned_network_address"].first
        end
        return r
      end

      def check_or_reserve_subnet()
        @logger.info("Checking if a subnet has been reserved")
        oarstat = exec("oarstat --json")
        oarstat = JSON.load(oarstat)
        job = oarstat.select!{ |k,v| v["owner"] == @username && v["name"] == JOB_SUBNET_NAME }.values.first
        if job.nil?
          # we have to reserve a subnet
          @logger.info("Reserving a subnet")
          job_id = exec("oarsub -l \"slash_22=1, walltime=#{WALLTIME}\" --name #{JOB_SUBNET_NAME} \"sleep 3600\" | grep OAR_JOB_ID | cut -d '='  -f2").chomp
          begin
            retryable(:on => VagrantPlugins::G5K::Errors::JobNotRunning, :tries => 5, :sleep => 1) do
              @logger.info("Waiting for the job to be running")
              job = check_job(job_id)
              if job.nil? or job["state"] != "Running"
                raise VagrantPlugins::G5K::Errors::JobNotRunning 
              end
              break
            end
          rescue VagrantPlugins::G5K::Errors::JobNotRunning
            @logger.error("Tired of waiting")
            raise VagrantPlugins::G5K::Errors::JobNotRunning
          end
        end
        # get the macs ips addresses pool
        im = exec("g5k-subnets -j #{job["Job_Id"]} -im")
        @pool = im.split("\n").map{|i| i.split("\t")}
        @ip, @mac = @pool[0]
        @logger.info("Get the mac #{mac} and the corresponding ip #{ip} from the subnet")
      end


      def launch_vm(env)
        launcher_path = File.join(File.dirname(__FILE__), LAUNCHER_SCRIPT)
        @logger.info("Launching the VM on Grid'5000")
        # Checking the subnet job
        subnet = check_or_reserve_subnet()
        @logger.info("Uploading launcher")
        # uploading the launcher
        launcher_remote_path = File.join("/home", @username , WORKING_DIR, LAUNCHER_SCRIPT)
        upload(launcher_path, launcher_remote_path)
        # creating the params file
        params_path = File.join("/home", @username, WORKING_DIR, 'params')
        exec("echo #{@image_location} #{@mac} > #{params_path}")
        # Submitting a new job
        @logger.info("Starting a new job")
        job_id = exec("oarsub -t allow_classic_ssh -l \"{virtual!=\'none\'}/nodes=1,walltime=#{WALLTIME}\" --name #{env[:machine].name} --checkpoint 60 --signal 12  --array-param-file #{params_path} #{launcher_remote_path} | grep OAR_JOB_ID | cut -d '='  -f2").chomp
        

        begin
          retryable(:on => VagrantPlugins::G5K::Errors::JobNotRunning, :tries => 5, :sleep => 1) do
            @logger.info("Waiting for the job to be running")
            job = check_job(job_id)
            if job.nil? or job["state"] != "Running"
              raise VagrantPlugins::G5K::Errors::JobNotRunning 
            end
            # saving the id
            env[:machine].id = job["Job_Id"]
            break
          end
        rescue VagrantPlugins::G5K::Errors::JobNotRunning
          @logger.error("Tired of waiting")
          raise VagrantPlugins::G5K::Errors::JobNotRunning
        end
        @logger.info("VM booted on Grid'5000")

      end


      def exec(cmd)
        @logger.info("Executing #{cmd}")
        stdout = ""
        @session.exec!(cmd) do |channel, stream, data| 
          stdout << data
        end
        return stdout
      end

      def upload(src, dst)
        @session.scp.upload!(src, dst)
      end




    end
  end
end

    
