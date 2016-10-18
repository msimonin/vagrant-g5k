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

      # G5K gateway
      #
      # @return [String]
      attr_accessor :gateway

      # G5K image
      #
      # @return [Hash]
      attr_accessor :image


      # G5K network options
      # 
      #
      # @return [Hash]
      attr_accessor :net

      # OAR resource selection
      # 
      #
      # @return [String]
      attr_accessor :oar

      def initialize()
        @username         = ENV['USER']
        @project_id       = nil
        @site             = nil
        @gateway          = nil
        @walltime         = "01:00:00"
        @oar              = ""
        @net              = {
          'type' => 'nat',
          'ports' => ['2222-,22']
        }
      end

      def finalize!()
        # This is call by the plugin mecanism after initialize
      end


      def validate(machine)
        errors = _detected_errors

        errors << "g5k project_id is required" if @project_id.nil?
        errors << "g5k site is required" if @site.nil?
        errors << "g5k image is required" if @image.nil?
        errors << "g5k image must be a Hash" if !@image.is_a?(Hash)
        
        { "G5K Provider" => errors }
      end

    end
  end
end

