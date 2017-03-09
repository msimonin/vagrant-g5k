require "pathname"

require "vagrant/action/builder"

module VagrantPlugins
  module G5K
    module Action
      # Include the built-in modules so we can use them as top-level things.
      include Vagrant::Action::Builtin

      # This action is called to read the state of the machine. The
      # resulting state is expected to be put into the `:machine_state_id`
      # key.
      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectG5K
          b.use ReadState
        end
      end

       # This action is called to read the SSH info of the machine. The
      # resulting state is expected to be put into the `:machine_ssh_info`
      # key.
      def self.action_read_ssh_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectG5K
          b.use ReadSSHInfo
        end
      end

       # This action is called to SSH into the machine.
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          # read_state is hook by the call to machine.state.id
          # in GetState Middleware
          b.use Call, GetState do |env, b2|
            if env[:result] != :Running
              b2.use MessageNotRunning
              next
            end
            b2.use SSHExec
          end
        end
      end


      # This action is called when vagrant ssh -C "..." is used
      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, GetState do |env, b2|
            if env[:result] != :Running
              b2.use MessageNotRunning
              next
            end

            b2.use SSHRun
          end
        end
      end


      # This action is called to bring the box up from nothing.
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, GetState do |env1, b1|
            if env1[:result] == :Running then
              b1.use MessageAlreadyRunning
            elsif env1[:result] == :Waiting
              b1.use ConnectG5K
              b1.use WaitInstance
            else
              b1.use ConnectG5K
              b1.use CreateLocalWorkingDir
              b1.use RunInstance # launch a new instance
              b1.use WaitForCommunicator, [:Running]
              b1.use SyncedFolders
            end
          end
        end
      end

      # This action is called to terminate the remote machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, DestroyConfirm do |env, b2|
            if env[:result]
              b2.use ConfigValidate
              b2.use ConnectG5K
              b2.use Call, GetState do |env2, b3|
                if [:Running, :Waiting].include?(env2[:result])
                  b3.use DeleteJob
                  b3.use DeleteDisk
                  next
                elsif env2[:result] == :shutdown
                  b3.use DeleteDisk
                  next
                else
                  b3.use MessageNotCreated
                  next
                end
              end
            else
              b2.use MessageWillNotDestroy
            end
          end
        end
      end

      # This action is called to shutdown the remote machine.
      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
            b.use ConfigValidate
            b.use ConnectG5K
            b.use Call, GetState do |env1, b2|
              if [:Running, :Waiting].include?(env1[:result])
                b2.use DeleteJob
                next
              else
                b2.use MessageNotCreated
                next
              end
          end
        end
      end

       # This action is called when `vagrant provision` is called.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, GetState do |env, b2|
            if env[:result] != :Running
              b2.use MessageNotRunning
              next
            end
            b2.use Provision
          end
        end
      end

      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :ConnectG5K, action_root.join("connect_g5k")
      autoload :CreateLocalWorkingDir, action_root.join("create_local_working_dir")
      autoload :DeleteJob, action_root.join("delete_job")
      autoload :DeleteDisk, action_root.join("delete_disk")
      autoload :GetState, action_root.join("get_state")
      autoload :MessageAlreadyRunning, action_root.join("message_already_running")
      autoload :MessageNotCreated, action_root.join("message_not_created")
      autoload :MessageNotRunning, action_root.join("message_not_running")
      autoload :ReadSSHInfo, action_root.join("read_ssh_info")
      autoload :ReadState, action_root.join("read_state")
      autoload :RunInstance, action_root.join("run_instance")
      autoload :StartInstance, action_root.join("start_instance")
      autoload :WaitInstance, action_root.join("wait_instance")


    end
  end
end

