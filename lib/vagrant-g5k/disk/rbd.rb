require 'log4r'

module VagrantPlugins
  module G5K
    module Disk

      class RBD
      
        include Vagrant::Util::Retryable

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
        @logger.debug(@image)
        if [STRATEGY_SNAPSHOT, STRATEGY_DIRECT].include?(strategy)
          @logger.debug(@image)
          file = File.join(@image[:pool], @image[:rbd])
          @logger.debug(file)
        elsif strategy == STRATEGY_COW
          file = _clone_or_copy_image(clone = true)
        elsif strategy == STRATEGY_COPY
          file = _clone_or_copy_image(clone = false)
        end
        # encapsulate the file to a qemu ready disk description
        file = "rbd:#{file}:id=#{@image[:id]}:conf=#{@image[:conf]}:rbd_cache=true,cache=writeback"
        @logger.debug("Generated drive string : #{file}")
        return file
      end

      def check_storage()
        strategy = @image[:backing]
        file_to_check = ""
        if [STRATEGY_SNAPSHOT, STRATEGY_DIRECT].include?(strategy)
          file_to_check = @image[:rbd]
        else
          file_to_check = File.join(@cwd, @env[:machine].name.to_s)
        end
        @driver.exec("(rbd --pool #{@image[:pool]} --id #{@image[:id]} --conf #{@image[:conf]} ls | grep \"^#{file_to_check}$\") || echo \"\"")
      end

      def delete_disk()   
        disk = File.join(@image[:pool], @cwd, @env[:machine].name.to_s)
        begin
          retryable(:on => VagrantPlugins::G5K::Errors::CommandError, :tries => 10, :sleep => 5) do
            @driver.exec("rbd rm  #{disk} --conf #{@image[:conf]} --id #{@image[:id]}" )
            break
          end
        rescue VagrantPlugins::G5K::Errors::CommandError
          @ui.error("Reach max attempt while trying to remove the rbd")
          raise VagrantPlugins::G5K::Errors::CommandError
        end
      end



      def _clone_or_copy_image(clone = true)
        # destination in the same pool under the .vagrant ns
        destination = File.join(@image[:pool], @cwd, @env[:machine].name.to_s)
        # Even if nothing bad will happen when the destination already exist, we should test it before
        exists = check_storage()
        if exists == ""
          # we create the destination
          if clone
            # parent = pool/rbd@snap
            @ui.info("Cloning the rbd image")
            parent = File.join(@image[:pool], "#{@image[:rbd]}@#{@image[:snapshot]}")
            @driver.exec("rbd clone #{parent} #{destination} --conf #{@image[:conf]} --id #{@image[:id]}" )
          else
            @ui.info("Copying the rbd image (This may take some time)")
            # parent = pool/rbd@snap
            parent = File.join(@image[:pool], "#{@image[:rbd]}")
            @driver.exec("rbd cp #{parent} #{destination} --conf #{@image[:conf]} --id #{@image[:id]}" )
          end
        end
        return destination
      end


      end
    end
  end
end
