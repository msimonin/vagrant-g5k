require 'log4r'

module VagrantPlugins
  module G5K
    module Disk

      class Local

        def initialize(env, cwd,  driver)
          @logger = Log4r::Logger.new("vagrant::network::nat")
          # command driver is unused
          @cwd = cwd
          @driver = driver
          @env = env
          @image = env[:machine].provider_config.image
          @project_id = env[:machine].provider_config.project_id
          @ui = env[:ui]
        end

        def generate_drive()
          strategy = @image[:backing]
          if [STRATEGY_SNAPSHOT, STRATEGY_DIRECT].include?(strategy)
            file = @image[:path]
          elsif strategy == STRATEGY_COW
            file = _clone_or_copy_image(clone = true)
          elsif strategy == STRATEGY_COPY
            file = _clone_or_copy_image(clone = false)
          end
          return file
        end

        def check_storage()
          strategy = @image[:backing]
          file_to_check = ""
          if [STRATEGY_SNAPSHOT, STRATEGY_DIRECT].include?(strategy)
            file_to_check = @image[:path]
          else
            file_to_check = File.join(@cwd, @env[:machine].name.to_s)
          end
            @driver.exec("[ -f \"#{file_to_check}\" ] && echo #{file_to_check} || echo \"\"")
        end

        def delete_disk()
          disk = File.join(@cwd, @env[:machine].name.to_s)
          @driver.exec("rm -f #{disk}")
        end
        
        def _clone_or_copy_image( clone = true)
          @ui.info("Clone the file image")
          file = File.join(@cwd, @env[:machine].name.to_s)
          exists = check_storage()
          if exists == ""
            if clone 
              @driver.exec("qemu-img create -f qcow2 -b #{@image[:path]} #{file}")
            else
              @driver.exec("cp #{@image[:path]} #{file}")
            end
          end
          return file
        end

 
      end
    end
  end
end

  
