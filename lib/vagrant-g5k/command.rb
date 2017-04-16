require 'net/ssh/multi'
require 'vagrant-g5k/g5k_connection'
include Process

module VagrantPlugins
  module G5K
    class Command < Vagrant.plugin('2', :command)

      # Show description when `vagrant list-commands` is triggered
      def self.synopsis
        "plugin: vagrant-g5k: manage virtual machines on grid'5000"
      end

      def execute
        puts 'Nothing implemented yet ;)'
      end

    end
  end
end

