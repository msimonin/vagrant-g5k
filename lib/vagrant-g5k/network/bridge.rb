require 'log4r'

module VagrantPlugins
  module G5K
    module Network

      class Bridge

        include VagrantPlugins::G5K

        def initialize(env, driver, oar_driver)
          @logger = Log4r::Logger.new("vagrant::network::bridge")
          # command driver is unused
          @driver = driver
          @oar_driver = oar_driver
          @net = env[:machine].provider_config.net
          @project_id = env[:machine].provider_config.project_id
          @walltime = env[:machine].provider_config.walltime
        end

        def generate_net()
          lockable(:lock => VagrantPlugins::G5K.subnet_lock) do
            subnet_job_id = _find_subnet
            if subnet_job_id.nil?
              subnet_job_id = _create_subnet
              @oar_driver.wait_for(subnet_job_id)
              # we can't call this inside the launcher script
              # let's put it in a file instead...
              @driver.exec("g5k-subnets -j #{subnet_job_id} -im > #{_subnet_file}" )
              # initialize subnet count
              @driver.exec("echo 0 > #{_subnet_count}")
            end
          return "BRIDGE #{_subnet_file}"
          end
        end

        def check_state(job_id)
          subnet_job_id = _find_subnet()
          return :subnet_missing if subnet_job_id.nil?
          nil
        end

        def attach()
          _update_subnet_use("+")
        end

        def detach()
          _update_subnet_use("-")
        end

        def vm_ssh_info(vmid)
          subnet = @driver.exec("cat  #{_subnet_file}" )
                        .split("\n")
                        .map{|macip| macip.split("\t")}
          # recalculate ip given to this VM
          macip = subnet[vmid.to_i.modulo(1022)]
          return {
            :host => macip[0]
          }
        end


        def _cwd()
          # remote working directory
          File.join(".vagrant", @project_id)
        end


        def _create_subnet()
          options = []
          options << "--name '#{@project_id}-net'"
          options << "-l 'slash_18=1, walltime=#{@walltime}'"
          @oar_driver.submit_job('sleep 84400', options )
        end

        def _subnet_file()
          return File.join(_cwd(), 'subnet')
        end

        def _subnet_count()
          return File.join(_cwd(), 'subnet-count')
        end

        def _find_subnet()
          job = @oar_driver.look_by_name("#{@project_id}-net")
          return job["Job_Id"] unless job.nil?
          nil
        end

        # Update the subnet use
        # op is a string "+" or "-"
        # if after the update the subnet use is 0
        # the subnet in use is also deleted
        def _update_subnet_use(op)
          cmd = []
          cmd << "c=$(cat #{_subnet_count});"
          cmd << "echo $(($c #{op} 1)) > #{_subnet_count};"
          cmd << "cat #{_subnet_count}"
          count = @driver.exec(cmd.join(" "))
          @logger.info("subnet_count = #{count}")
          if count.to_i <= 0
            @logger.info("deleteting the associated subnet")
            subnet_id = _find_subnet()
            @oar_driver.delete_job(subnet_id)

          end

        end

      end
    end
  end
end
