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

      # G5K project_id
      #
      # @return [String]
      attr_accessor :project_id

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

      def initialize()
        @username         = nil
        @project_id       = nil
        @site             = "rennes"
        @walltime         = "01:00:00"
      end

      def finalize!()
        # This is call by the plugin mecanism after initialize
      end


      def validate(machine)
        errors = _detected_errors

        errors << "g5k username is required" if @username.nil?
        errors << "g5k image is required" if @image.nil?
        errors << "g5k image is required" if @project_id.nil?

        # TODO validate image hash
        { "G5K Provider" => errors }
      end

    end
  end
end

