require "vagrant"
require "iniparse"

module VagrantPlugins
  module G5K
    class Config < Vagrant.plugin("2", :config)
      # G5K username
      #
      # @return [String]
      attr_accessor :username

      # G5K site
      #
      # @return [String]
      attr_accessor :site
      # G5K image location (path)
      #
      # @return [String]
      attr_accessor :image_location

      # G5K image location (path)
      #
      # @return [String]
      attr_accessor :image_type

      # G5K image strategy
      # 
      #
      # @return [String]
      attr_accessor :image_strategy

      # G5K ports mapping
      # 
      #
      # @return [Array]
      attr_accessor :ports

      def initialize()
        @username     = nil
        @image_location = nil
        @site = "rennes"
        @image_type     = "local"
        @image_strategy = "snapshot"
      end

      def finalize!()
        # This is call by the plugin mecanism after initialize
      end


      def validate(machine)
        errors = _detected_errors

        errors << "g5k username is required" if @username.nil?
        errors << "g5k image_location is required" if @image_location.nil?

        { "G5K Provider" => errors }
      end

    end
  end
end

