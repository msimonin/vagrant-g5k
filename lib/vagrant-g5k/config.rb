require "vagrant"
require "iniparse"

module VagrantPlugins
  module G5K
    class Config < Vagrant.plugin("2", :config)
      # G5K username
      #
      # @return [String]
      attr_accessor :username

      # G5K private_key
      #
      # @return [String]
      attr_accessor :private_key

      # G5K walltime
      #
      # @return [String]
      attr_accessor :walltime

      # G5K site
      #
      # @return [String]
      attr_accessor :site

      # G5K image
      #
      # @return [Hash]
      attr_accessor :image


      # G5K ports mapping
      # 
      #
      # @return [Array]
      attr_accessor :ports

      # G5K backing strategy
      # 
      #
      # @return [String]
      attr_accessor :backing_strategy

      def initialize()
        @username     = nil
        @site = "rennes"
        @backing_strategy = ""
        @walltime = "01:00:00"
      end

      def finalize!()
        # This is call by the plugin mecanism after initialize
      end


      def validate(machine)
        errors = _detected_errors

        errors << "g5k username is required" if @username.nil?
        errors << "g5k image_location is required" if @image.nil?
        # TODO validate image hash
        { "G5K Provider" => errors }
      end

    end
  end
end

