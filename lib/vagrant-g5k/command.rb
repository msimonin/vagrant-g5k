require 'net/ssh/multi'
require 'vagrant-g5k/util/g5k_connection'
include Process

module VagrantPlugins
  module G5K
    class Command < Vagrant.plugin('2', :command)

      # Show description when `vagrant list-commands` is triggered
      def self.synopsis
        "plugin: vagrant-g5k: manage virtual machines on grid'5000"
      end

      def execute
        # TODO
        options = {}
        opts = OptionParser.new do |o|
          o.banner = 'Usage: vagrant g5k [vm-name]'
          o.separator ''
          o.version = VagrantPlugins::G5K::VERSION
          o.program_name = 'vagrant g5k'
        end
        argv = parse_options(opts)
        with_target_vms(argv, options) do |machine|
          puts machine.config.vm.networks
        end
        puts "sleeping"
        wait
      end
    end
  end
end

