require 'net/ssh/multi'
require 'net/scp'
require 'json'

require 'vagrant/util/retryable'

WORKING_DIR = ".vagrant-g5k"
LAUNCHER_SCRIPT = "launch_vm_fwd.sh"
JOB_SUBNET_NAME = "vagrant-g5k-subnet"
WALLTIME="01:00:00"

module VagrantPlugins
  module G5K
    class Connection
      include Vagrant::Util::Retryable

      attr_accessor :session

      attr_accessor :username

      attr_accessor :private_key

      attr_accessor :site

      attr_accessor :image_location

      attr_accessor :logger

      attr_accessor :node
      
      attr_accessor :pool

      attr_accessor :ports

      attr_accessor :backing_strategy

      # legacy
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
        @logger.info("connecting with #{@username} on site #{@site}")
        options = {
          :forward_agent => true
        }
        options[:keys] = [@private_key] if !@private_key.nil?
        gateway = Net::SSH::Gateway.new("access.grid5000.fr", @username, options)

        @session = gateway.ssh(@site, @username, options)
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

      def launch_vm(env)
        launcher_path = File.join(File.dirname(__FILE__), LAUNCHER_SCRIPT)
        @logger.info("Launching the VM on Grid'50001")
        # Checking the subnet job
        @logger.info("Uploading launcher")
        # uploading the launcher
        launcher_remote_path = File.join("/home", @username , WORKING_DIR, LAUNCHER_SCRIPT)
        upload(launcher_path, launcher_remote_path)

        # Generate partial arguments for the kvm command
        drive = _generate_drive()
        net = _generate_net()
        # TODO implement different backing strategy
        snapshot_flag = "-snapshot" if @backing_strategy == "snapshot"

        args = [drive, net, snapshot_flag].join(" ")
        # Submitting a new job
        @logger.info("Starting a new job")
        job_id = exec("oarsub -t allow_classic_ssh -l \"{virtual!=\'none\'}/nodes=1,walltime=#{WALLTIME}\" --name #{env[:machine].name} --checkpoint 60 --signal 12  \"#{launcher_remote_path} #{args}\" | grep OAR_JOB_ID | cut -d '='  -f2").chomp
        

        begin
          retryable(:on => VagrantPlugins::G5K::Errors::JobNotRunning, :tries => 100, :sleep => 2) do
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

      def _generate_drive()
        return "-drive file=#{@image_location},if=virtio"
      end

      def _generate_net()
        fwd_ports = @ports.map do |p|
          "hostfwd=tcp::#{p}"
        end.join(',')
        net = "-net nic,model=virtio -net user,#{fwd_ports}"
        return net
      end


    end
  end
end

    
