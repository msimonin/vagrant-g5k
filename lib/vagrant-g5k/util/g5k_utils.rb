require 'net/ssh/multi'
require 'net/scp'
require 'json'
require 'digest'

require 'vagrant/util/retryable'

LAUNCHER_SCRIPT = "launch_vm_fwd.sh"

STRATEGY_SNAPSHOT = "snapshot"
STRATEGY_COPY = "copy"
STRATEGY_COW = "cow"
STRATEGY_DIRECT = "direct"

module VagrantPlugins
  module G5K
    class Connection
      include Vagrant::Util::Retryable

      attr_accessor :session

      attr_accessor :username

      attr_accessor :project_id

      attr_accessor :private_key

      attr_accessor :site

      attr_accessor :walltime

      attr_accessor :image_location

      attr_accessor :logger

      attr_accessor :node
      
      attr_accessor :pool

      attr_accessor :ports

      def initialize(args)
        # initialize
        args.each do |k,v|
          instance_variable_set("#{k}", v) unless v.nil?
        end
        @logger = Log4r::Logger.new("vagrant::environment")
        @logger.debug("connecting with #{@username} on site #{@site}")
        options = {
          :forward_agent => true
        }
        options[:keys] = [@private_key] if !@private_key.nil?
        gateway = Net::SSH::Gateway.new("access.grid5000.fr", @username, options)
        @session = gateway.ssh(@site, @username, options)
      end

      def create_local_working_dir(env)
        @session.exec("mkdir -p #{cwd(env)}")
      end

      def cwd(env)
        # remote working directory
        File.join("/home", @username, ".vagrant", @project_id)
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

      def check_local_storage(env)
        # Is the disk image already here ?
        if @image["pool"].nil?
          file = _check_file_local_storage(env)
        else
          file = _check_rbd_local_storage(env)
        end
        return file if file != ""
        return nil
      end

      def _check_file_local_storage(env)
        strategy = @image["backing"]
        file_to_check = ""
        if [STRATEGY_SNAPSHOT, STRATEGY_DIRECT].include?(strategy)
          file_to_check = @image[path]
        else
          file_to_check = File.join(cwd(env), env[:machine].name.to_s)
        end
          exec("[ -f \"#{file_to_check}\" ] && echo #{file_to_check} || echo \"\"")
      end
  
      def _check_rbd_local_storage(env)
        strategy = @image["backing"]
        file_to_check = ""
        if [STRATEGY_SNAPSHOT, STRATEGY_DIRECT].include?(strategy)
          file_to_check = @image[path]
        else
          file_to_check = File.join(cwd(env), env[:machine].name.to_s)[1..-1]
        end
        exec("(rbd --pool #{@image["pool"]} --id #{@image["id"]} --conf #{@image["conf"]} ls | grep #{file_to_check}) || echo \"\"")
      end


      def launch_vm(env)
        launcher_path = File.join(File.dirname(__FILE__), LAUNCHER_SCRIPT)
        @ui.info("Launching the VM on Grid'5000")
        # Checking the subnet job
        # uploading the launcher
        launcher_remote_path = File.join(cwd(env), LAUNCHER_SCRIPT)
        upload(launcher_path, launcher_remote_path)

        # Generate partial arguments for the kvm command
        drive = _generate_drive(env)
        net = _generate_net()

        args = [drive, net].join(" ")
        # Submitting a new job
        job_id = exec("oarsub -t allow_classic_ssh -l \"{virtual!=\'none\'}/nodes=1,walltime=#{@walltime}\" --name #{env[:machine].name} --checkpoint 60 --signal 12  \"#{launcher_remote_path} #{args}\" | grep OAR_JOB_ID | cut -d '='  -f2").chomp
        

        begin
          retryable(:on => VagrantPlugins::G5K::Errors::JobNotRunning, :tries => 100, :sleep => 2) do
            @ui.info("Waiting for the job to be running")
            job = check_job(job_id)
            if job.nil? or job["state"] != "Running"
              raise VagrantPlugins::G5K::Errors::JobNotRunning 
            end
            # saving the id
            env[:machine].id = job["Job_Id"]
            break
          end
        rescue VagrantPlugins::G5K::Errors::JobNotRunning
          @ui.error("Tired of waiting")
          raise VagrantPlugins::G5K::Errors::JobNotRunning
        end
        @ui.info("VM booted on Grid'5000")

      end

      def delete_disk(env)
        if [STRATEGY_DIRECT, STRATEGY_SNAPSHOT].include?(@image["backing"])
          @ui.error("Destroy not support for the strategy #{@image["backing"]}")
          return
        end

        if @image["pool"].nil?
          disk = File.join(cwd(env), env[:machine].name.to_s)
          exec("rm #{disk}")
        else
          disk = File.join(@image["pool"], cwd(env), env[:machine].name.to_s)
          begin
            retryable(:on => VagrantPlugins::G5K::Errors::CommandError, :tries => 10, :sleep => 5) do
              exec("rbd rm  #{disk} --conf #{@image["conf"]} --id #{@image["id"]}" )
              break
            end
          rescue VagrantPlugins::G5K::Errors::CommandError
            @ui.error("Reach max attempt while trying to remove the rbd")
            raise VagrantPlugins::G5K::Errors::CommandError
          end
        end
      end


      def exec(cmd)
        @logger.debug("Executing #{cmd}")
        stdout = ""
        stderr = ""
        exit_code = 0
        @session.open_channel do |channel|
          channel.exec(cmd) do |ch, success|
            abort "could not execute command" unless success

            channel.on_data do |c, data|
              stdout << data.chomp
            end

            channel.on_extended_data do |c, type, data|
              stderr << data.chomp
            end

            channel.on_request("exit-status") do |c,data|
              exit_code = data.read_long
            end

            channel.on_close do |c|
            end
          end
        end
        @session.loop
        if exit_code != 0
          @logger.error(:stderr => stderr, :code => exit_code)
          raise VagrantPlugins::G5K::Errors::CommandError
        end
        @logger.debug("Returning #{stdout}")
        stdout
      end

      def upload(src, dst)
        @session.scp.upload!(src, dst)
      end

      def _generate_drive(env)
        # Depending on the strategy we generate the file location
        # This code smells a bit better 
        file = ""
        snapshot = ""
        if @image["backing"] == STRATEGY_SNAPSHOT
          snapshot = "-snapshot"
        end

        if @image["pool"].nil?
          file = _generate_drive_local(env)
        else
          file = _generate_drive_rbd(env)
        end
      
        return "-drive file=#{file},if=virtio #{snapshot}"
      end

      def _generate_drive_rbd(env)
        strategy = @image["backing"]
        if [STRATEGY_SNAPSHOT, STRATEGY_DIRECT].include?(strategy)
          file = @image["path"]
        elsif strategy == STRATEGY_COW
          file = _rbd_clone_or_copy_image(env, clone = true)
        elsif strategy == STRATEGY_COPY
          file = _rbd_clone_or_copy_image(env, clone = false)
        end
        return file
      end

      def _generate_drive_local(env)
        strategy = @image["backing"]
        if [STRATEGY_SNAPSHOT, STRATEGY_DIRECT].include?(strategy)
          file = @image["path"]
        elsif strategy == STRATEGY_COW
          file = _file_clone_or_copy_image(env, clone = true)
        elsif strategy == STRATEGY_COPY
          file = _file_clone_or_copy_image(env, clone = false)
        end
        return file
      end

      def _rbd_clone_or_copy_image(env, clone = true)
        @ui.info("Clone the rbd image")
        # destination in the same pool under the .vagrant ns
        destination = File.join(@image["pool"], cwd(env), env[:machine].name.to_s)
        # Even if nothing will happen when the destination already exist, we should test it before
        exists = _check_rbd_local_storage(env)
        if exists == ""
          # we create the destination
          if clone
            # parent = pool/rbd@snap
            parent = File.join(@image["pool"], "#{@image["rbd"]}@#{@image["snapshot"]}")
            exec("rbd clone #{parent} #{destination} --conf #{@image["conf"]} --id #{@image["id"]}" )
          else
            # parent = pool/rbd@snap
            parent = File.join(@image["pool"], "#{@image["rbd"]}")
            exec("rbd cp #{parent} #{destination} --conf #{@image["conf"]} --id #{@image["id"]}" )
          end
        end
        return "rbd:#{destination}:id=#{@image["id"]}:conf=#{@image["conf"]}"
      end
      
      def _file_clone_or_copy_image(env, clone = true)
          @ui.info("Clone the file image")
          file = File.join(cwd(env), env[:machine].name.to_s)
          exists = _check_file_local_storage(env)
          if exists == ""
            if clone 
              exec("qemu-img create -f qcow2 -b #{@image["path"]} #{file}")
            else
              exec("cp #{@image["path"]} #{file}")
            end
          end
          return file
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

    
