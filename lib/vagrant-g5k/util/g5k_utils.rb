require 'net/ssh/multi'
require 'net/scp'
require 'json'
require 'digest'
require 'thread'

require 'vagrant/util/retryable'

LAUNCHER_SCRIPT = "launch_vm_fwd.sh"
LAUNCHER_BRIDGE_SCRIPT = "launch_vm_bridge.sh"

STRATEGY_SNAPSHOT = "snapshot"
STRATEGY_COPY = "copy"
STRATEGY_COW = "cow"
STRATEGY_DIRECT = "direct"

module VagrantPlugins
  module G5K
    class Connection
      include Vagrant::Util::Retryable
      include VagrantPlugins::G5K

      attr_accessor :driver

      attr_accessor :username

      attr_accessor :gateway

      attr_accessor :project_id

      attr_accessor :private_key

      attr_accessor :site

      attr_accessor :walltime

      attr_accessor :logger

      attr_accessor :node

      attr_accessor :net
      
      attr_accessor :oar
    
      def initialize(env, driver)
        # provider specific config
        @provider_config = env[:machine].provider_config 
        @username = @provider_config.username
        @project_id = @provider_config.project_id
        @private_key = @provider_config.private_key
        @site = @provider_config.site
        @walltime = @provider_config.walltime
        @image= @provider_config.image
        @gateway = @provider_config.gateway
        @oar = "{#{@provider_config.oar}}/" if @provider_config.oar != ""
        @net = @provider_config.net
        # grab the network config of the vm
        # @networks = env[:machine].config.vm.networks
        # to log to the ui
        @ui = env[:ui]

        @logger = Log4r::Logger.new("vagrant::environment")
        @driver = driver

      end


      def create_local_working_dir()
        exec("mkdir -p #{cwd()}")
      end

      def cwd()
        # remote working directory
        File.join(".vagrant", @project_id)
      end


      def check_job(job_id)
        # Note: when switching from on site to another
        # this command may failed due the job_id that has nothing 
        # to do with the new site. 
        r = nil
        begin
          oarstat = exec("oarstat -j #{job_id} --json")
          # json is 
          # { "job_id" : {description}}
          r = JSON.load(oarstat)["#{job_id}"]
          if !r.nil?
            @node = r["assigned_network_address"].first
          end
        rescue VagrantPlugins::G5K::Errors::CommandError
          @logger.debug "Rescued error when executing the command"
        end

        return r
      end

      def process_errors(job_id)
        job = check_job(job_id)
        stderr_file = job["stderr_file"]
        stderr = exec("cat #{stderr_file}")
        @ui.error("#{stderr_file}:  #{stderr}")
        raise VagrantPlugins::G5K::Errors::JobError
      end

      def delete_job(job_id)
        @ui.info("Soft deleting the associated job")
        begin
          exec("oardel -c -s 12 #{job_id}")
        rescue VagrantPlugins::G5K::Errors::CommandError
          @logger.debug "Checkpointing failed, sending hard deletion"
          @ui.warn("Soft delete failed : proceeding to hard delete")
          exec("oardel #{job_id}")
        ensure
          _update_subnet_use("-")
        end
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
          file_to_check = @image["path"]
        else
          file_to_check = File.join(cwd(), env[:machine].name.to_s)
        end
          exec("[ -f \"#{file_to_check}\" ] && echo #{file_to_check} || echo \"\"")
      end
  
      def _check_rbd_local_storage(env)
        strategy = @image["backing"]
        file_to_check = ""
        if [STRATEGY_SNAPSHOT, STRATEGY_DIRECT].include?(strategy)
          file_to_check = @image["rbd"]
        else
          file_to_check = File.join(cwd(), env[:machine].name.to_s)
        end
        exec("(rbd --pool #{@image["pool"]} --id #{@image["id"]} --conf #{@image["conf"]} ls | grep \"^#{file_to_check}\") || echo \"\"")
      end


      def launch_vm(env)
        if @net["type"] == "bridge"
          launcher_path = File.join(File.dirname(__FILE__), LAUNCHER_BRIDGE_SCRIPT)
        else
          launcher_path = File.join(File.dirname(__FILE__), LAUNCHER_SCRIPT)
        end

        @ui.info("Launching the VM on #{@site}")
        # Checking the subnet job
        # uploading the launcher
        launcher_remote_path = File.join(cwd(), LAUNCHER_SCRIPT)
        upload(launcher_path, launcher_remote_path)

        # Generate partial arguments for the kvm command
        # NOTE: net is first dur the the shape of the bridge launcher script
        # TODO: clean / improve this (that smells)
        net = _generate_net()
        drive = _generate_drive(env)
        
        args = [net, drive].join(" ")
        # Submitting a new job
        # Getting the job_id as a ruby string
        cmd = []
        cmd << "oarsub"
        cmd << "--json"
        cmd << "-t allow_classic_ssh"
        cmd << "-l \"#{@oar}nodes=1,walltime=#{@walltime}\""
        cmd << "--name #{env[:machine].name}"
        cmd << "--checkpoint 60 --signal 12"
        cmd << "'#{launcher_remote_path} #{args}'"
        cmd << "| grep \"job_id\"| cut -d':' -f2"
        job_id = exec(cmd.join(" ")).gsub(/"/,"").strip
        # saving the id asap
        env[:machine].id = job_id
        wait_for_vm(job_id)
      end
     
      def wait_for_vm(job_id)
        _wait_for(job_id)
        _update_subnet_use("+")
        @ui.info("ready @#{@site} on #{@node}")
      end

      def _wait_for(job_id)
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
      end


      def delete_disk(env)
        if [STRATEGY_DIRECT, STRATEGY_SNAPSHOT].include?(@image["backing"])
          @ui.error("Destroy not support for the strategy #{@image["backing"]}")
          return
        end

        if @image["pool"].nil?
          disk = File.join(cwd(), env[:machine].name.to_s)
          exec("rm -f #{disk}")
        else
          disk = File.join(@image["pool"], cwd(), env[:machine].name.to_s)
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

      def close()
        # Terminate the driver
        @driver[:session].close
      end

      def exec(cmd)
        @driver.exec(cmd)
      end

      def upload(src, dst)
        @driver.upload(src, dst)
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
          file = File.join(@image["pool"], @image["rbd"])
        elsif strategy == STRATEGY_COW
          file = _rbd_clone_or_copy_image(env, clone = true)
        elsif strategy == STRATEGY_COPY
          file = _rbd_clone_or_copy_image(env, clone = false)
        end
        # encapsulate the file to a qemu ready disk description
        file = "rbd:#{file}:id=#{@image["id"]}:conf=#{@image["conf"]}:rbd_cache=true,cache=writeback"
        @logger.debug("Generated drive string : #{file}")
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
        # destination in the same pool under the .vagrant ns
        destination = File.join(@image["pool"], cwd(), env[:machine].name.to_s)
        # Even if nothing bad will happen when the destination already exist, we should test it before
        exists = _check_rbd_local_storage(env)
        if exists == ""
          # we create the destination
          if clone
            # parent = pool/rbd@snap
            @ui.info("Cloning the rbd image")
            parent = File.join(@image["pool"], "#{@image["rbd"]}@#{@image["snapshot"]}")
            exec("rbd clone #{parent} #{destination} --conf #{@image["conf"]} --id #{@image["id"]}" )
          else
            @ui.info("Copying the rbd image (This may take some time)")
            # parent = pool/rbd@snap
            parent = File.join(@image["pool"], "#{@image["rbd"]}")
            exec("rbd cp #{parent} #{destination} --conf #{@image["conf"]} --id #{@image["id"]}" )
          end
        end
        return destination
      end
      
      def _file_clone_or_copy_image(env, clone = true)
          @ui.info("Clone the file image")
          file = File.join(cwd(), env[:machine].name.to_s)
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
        net = ""
        @logger.debug(@net)
        if @net["type"] == "bridge"
          # we reserve a subnet if necessary and pick one mac/ip from it
          lockable(:lock => VagrantPlugins::G5K.subnet_lock) do
            subnet_job_id = _find_subnet
            if subnet_job_id.nil? 
              subnet_job_id = _create_subnet
              _wait_for(subnet_job_id)
              # we can't call this inside the launcher script
              # let's put it in a file instead...
              exec("g5k-subnets -j #{subnet_job_id} -im > #{_subnet_file}" )
              # initialize subnet count
              exec("echo 0 > #{_subnet_count}")
            end
            @subnet_id = subnet_job_id
            net = _subnet_file
          end
        else
        fwd_ports = @net["ports"].map do |p|
          "hostfwd=tcp::#{p}"
        end.join(',')
        net = "-net nic,model=virtio -net user,#{fwd_ports}"
        end

        @logger.debug("Generated net string : #{net}")
        return net
      end

      def _subnet_file()
        return File.join(cwd(), 'subnet')
      end

      def _subnet_count()
        return File.join(cwd(), 'subnet-count')
      end


      def _find_subnet(vmid = nil)
        begin
          jobs = exec("oarstat -u --json")
          jobs = JSON.load(jobs)
          s = jobs.select{|k,v| v["name"] == "#{@project_id}-net" }.values.first
          # we set @node to the ip in the vnet
          # if there's a subnet and a vmid, read the mac/ip 
          # rebuild the ip associated with that vm
          if not vmid.nil?
            subnet = exec("cat  #{_subnet_file}" )
                      .split("\n")
                      .map{|macip| macip.split("\t")}
            # recalculate ip given to this VM
            macip = subnet[vmid.to_i.modulo(1022)]
            @node = macip[0]
            @logger.debug("#{subnet.size} - #{vmid} - #{macip}")
          end
          return s["Job_Id"]
        rescue Exception => e
          @logger.debug(e)
        end
        nil
      end

      def _create_subnet()
        cmd = []
        cmd << "oarsub"
        cmd << "--json"
        cmd << "--name '#{@project_id}-net'"
        cmd << "-l 'slash_22=1, walltime=#{@walltime}' 'sleep 84400'"
        # getting the job_id for this subnet
        cmd << "| grep 'job_id'"
        cmd << "| cut -d':' -f2"

        exec(cmd.join(" ")).gsub(/"/,"").strip
      end

      # Update the subnet use 
      # op is a string "+" or "-"
      # if after the update the subnet use is 0 
      # the subnet in use is also deleted 
      def _update_subnet_use(op)
        if not @net['type'] == 'bridge'
          return
        end
        cmd = []
        cmd << "c=$(cat #{_subnet_count});"
        cmd << "echo $(($c #{op} 1)) > #{_subnet_count};"
        cmd << "cat #{_subnet_count}"
        count = exec(cmd.join(" "))
        @logger.info("subnet_count = #{count}")
        if count.to_i <= 0 
          @logger.info("deleteting the associated subnet")
          subnet_id = _find_subnet()
          exec("oardel #{subnet_id}")
        end

      end

    end
  end
end

    
