require 'log4r'

module VagrantPlugins
  module G5K
    module Network

      class Nat

        def initialize(env, driver, oar_driver)
          @logger = Log4r::Logger.new("vagrant::network::nat")
          # command driver is unused
          @env = env
          @driver = driver
          @oar_driver = oar_driver
          @net = env[:machine].provider_config.net
        end

        def generate_net()
          fwd_ports = @net[:ports].map do |p|
            "hostfwd=tcp::#{p}"
          end.join(',')
          net = "-net nic,model=virtio -net user,#{fwd_ports}"

          @logger.debug("Generated net string : #{net}")
          return "NAT #{net}"
        end

        def check_state(job_id)
          return nil
        end

        def attach()
          # noop
        end

        def detach()
          # noop
        end

        def vm_ssh_info(vmid)
          # get forwarded port 22
          ports = @net[:ports]
          ssh_fwd = ports.select{ |x| x.split(':')[1] == '22'}.first
          if ssh_fwd.nil?
            @env[:ui].error "SSH port 22 must be forwarded"
            raise Error "SSh port 22 isn't forwarded"
          end
          ssh_fwd = ssh_fwd.split('-:')[0]
          # get node hosting the vm
          job = @oar_driver.check_job(@env[:machine].id)
          ssh_info =  {
            :host => job["assigned_network_address"].first,
            :port => ssh_fwd
          }
          @logger.debug(ssh_info)
          ssh_info
        end


      end
    end
  end
end

  
