require 'net/ssh/multi'
require 'net/scp'
require 'json'
require 'digest'
require 'thread'

require 'vagrant/util/retryable'

LAUNCHER_SCRIPT = "util/launch_vm.sh"

STRATEGY_SNAPSHOT = "snapshot"
STRATEGY_COPY = "copy"
STRATEGY_COW = "cow"
STRATEGY_DIRECT = "direct"

module VagrantPlugins
  module G5K
    class Connection
      include Vagrant::Util::Retryable
      include VagrantPlugins::G5K

      def initialize(env, cwd, driver, oar_driver, net_driver, disk_driver)
        @logger = Log4r::Logger.new("vagrant::g5k_connection")
        @ui = env[:ui]

        @provider_config = env[:machine].provider_config
        @site = @provider_config.site
        @walltime = @provider_config.walltime
        @image= @provider_config.image
        @oar = "{#{@provider_config.oar}}/" if @provider_config.oar != ""
        @resources = @provider_config.resources
        @oar_unit = init_oar_unit(@resources[:cpu], @resources[:mem])
        @job_container_id = @provider_config.job_container_id
        @cwd = cwd
        @driver = driver
        @oar_driver = oar_driver
        @net_driver = net_driver
        @disk_driver = disk_driver
      end

      def init_oar_unit(cpu, mem)
        if cpu != -1 and mem != -1
          unit = "nodes=1/core=#{cpu}"
        else
          unit = "nodes=1"
        end
        return unit
      end


      def create_local_working_dir()
        exec("mkdir -p #{@cwd}")
      end

      def check_job(job_id)
        @oar_driver.check_job(job_id)
      end

      def check_net(job_id)
        @net_driver.check_state(job_id)
      end

      def vm_ssh_info(vmid)
        @net_driver.vm_ssh_info(vmid)
      end

      def delete_job(job_id)
        @ui.info("Soft deleting the associated job")
        begin
          @oar_driver.delete_job(job_id, ["-c", "-s 12"])
        rescue VagrantPlugins::G5K::Errors::CommandError
          @logger.debug "Checkpointing failed, sending hard deletion"
          @ui.warn("Soft delete failed : proceeding to hard delete")
          @oar_driver.delete_job(job_id)
        ensure
          @net_driver.detach()
        end
      end

      def check_storage(env)
        # Is the disk image already here ?
        file = @disk_driver.check_storage()
        return file if file != ""
        return nil
      end

      def launch_vm(env)
        launcher_path = File.join(File.dirname(__FILE__), LAUNCHER_SCRIPT)
        @ui.info("Launching the VM on #{@site}")
        # Checking the subnet job
        # uploading the launcher
        launcher_remote_path = File.join(@cwd, File.basename(LAUNCHER_SCRIPT))
        upload(launcher_path, launcher_remote_path)

        # Generate partial arguments for the kvm command
        # NOTE: net is first due the the shape of the bridge launcher script
        net = @net_driver.generate_net()
        drive = _generate_drive(env)
        args = [@resources[:cpu], @resources[:mem], net, drive].join(" ")
        # Submitting a new job
        # Getting the job_id as a ruby string
        options = []
        if !@job_container_id.nil?
          @ui.info("Using a job container = #{@job_container_id}")
          options << "-t inner=#{@job_container_id}"
        end
        options += [
          "-l \"#{@oar}#{@oar_unit}, walltime=#{@walltime}\"",
          "--name #{env[:machine].name}",
          "--checkpoint 60",
          "--signal 12"
        ]
        job_id = @oar_driver.submit_job("#{launcher_remote_path} #{args}", options)
        # saving the id asap
        env[:machine].id = job_id
        wait_for_vm(job_id)
      end

      def wait_for_vm(job_id)
        @oar_driver.wait_for(job_id)
        @net_driver.attach()
        @ui.info("ready @#{@site}")
      end


      def delete_disk(env)
        if [STRATEGY_DIRECT, STRATEGY_SNAPSHOT].include?(@image[:backing])
          @ui.error("Destroy not support for the strategy #{@image[:backing]}")
          return
        end
        @disk_driver.delete_disk()
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
        if @image[:backing] == STRATEGY_SNAPSHOT
          snapshot = "-snapshot"
        end
        file = @disk_driver.generate_drive()
      
        return "-drive file=#{file},if=virtio #{snapshot}"
      end

    end
  end
end

