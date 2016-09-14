require 'net/ssh/multi'
require 'vagrant-g5k/util/g5k_utils'

module VagrantPlugins
  module G5K
    class Command < Vagrant.plugin('2', :command)

      # Show description when `vagrant list-commands` is triggered
      def self.synopsis
        "plugin: vagrant-g5k: manage virtual machines on grid'5000"
      end

      def execute
        # TODO
      end

    end
  end
end

