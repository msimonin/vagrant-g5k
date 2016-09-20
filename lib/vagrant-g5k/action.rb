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
          # read the state to find the enclosing ressource
          b.use ReadState
          b.use ReadSSHInfo
        end
      end

       # This action is called to SSH into the machine.
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end
            b2.use SSHExec
          end
        end
      end

      # This action is called to bring the box up from nothing.
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectG5K
          b.use CreateLocalWorkingDir
          b.use Call, IsCreated do |env1, b1|
            if env1[:result] then
              b1.use MessageAlreadyCreated
            else
              b1.use RunInstance # launch a new instance
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
              b2.use Call, IsCreated do |env2, b3|
                if !env2[:result]
                  b3.use MessageNotCreated
                  next
                end
                b3.use DeleteJob
                b3.use DeleteDisk
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
            b.use Call, IsCreated do |env1, b2|
              if !env1[:result]
                b2.use MessageNotCreated
                next
              end
            b2.use DeleteJob
          end
        end
      end

       # This action is called when `vagrant provision` is called.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
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
      autoload :IsCreated, action_root.join("is_created")
      autoload :MessageAlreadyCreated, action_root.join("message_already_created")
      autoload :MessageNotCreated, action_root.join("message_not_created")
      autoload :ReadSSHInfo, action_root.join("read_ssh_info")
      autoload :ReadState, action_root.join("read_state")
      autoload :RunInstance, action_root.join("run_instance")
      autoload :StartInstance, action_root.join("start_instance")

    end
  end
end

