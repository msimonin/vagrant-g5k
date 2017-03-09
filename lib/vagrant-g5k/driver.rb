require "log4r"

module VagrantPlugins
  module G5K
    class Driver
      def initialize(session, lock)
        @logger   = Log4r::Logger.new("vagrant::g5k::driver")
        @lock = lock
        @session = session
      end

      def exec(cmd)
        @logger.debug("Executing #{cmd}")
        stdout = ""
        stderr = ""
        exit_code = 0
        @lock.synchronize{
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
        }
        stdout

      end

      def upload(src, dst)
        @lock.synchronize {
          @session.scp.upload!(src, dst)
       }
      end

    end
  end
end

