require "pathname"

require "vagrant-g5k/plugin"
require 'thread'

module VagrantPlugins
  module G5K

    class << self
      attr_accessor :g5k_lock
      attr_accessor :pool
    end
    @g5k_lock = Mutex.new
    @pool = {}

    lib_path = Pathname.new(File.expand_path("../vagrant-g5k", __FILE__))
    autoload :Action, lib_path.join("action")
    autoload :Errors, lib_path.join("errors")

    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
    end

    def lockable(opts)
      opts[:lock].synchronize {
        yield
      }
    end


  end
end
