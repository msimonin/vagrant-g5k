require "log4r"
require "vagrant-g5k/g5k_connection"
require "vagrant-g5k/driver"
require "vagrant-g5k/oar"
require "vagrant-g5k/network/nat"
require "vagrant-g5k/network/bridge"
require "vagrant-g5k/disk/local"
require "vagrant-g5k/disk/rbd"
require 'thread'


module VagrantPlugins
  module G5K


    module Action
      # This action connects to G5K, verifies credentials work, and
      # puts the G5K connection object into the `:g5k_connection` key
      # in the environment.
      class ConnectG5K

        include VagrantPlugins::G5K

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_g5k::action::connect_g5k")
        end

        def call(env)
          cwd = File.join('.vagrant', env[:machine].provider_config.project_id)
          driver = _get_driver(env)
          oar_driver = VagrantPlugins::G5K::Oar.new(env[:ui], driver)
          net_driver = _get_net_driver(env, driver, oar_driver)
          disk_driver = _get_disk_driver(env, cwd, driver)
          env[:g5k_connection] = Connection.new(env, cwd, driver, oar_driver, net_driver, disk_driver)
          @app.call(env)
        end

        # get a session object to use to connect to the oar scheduler
        # this connection is share for all actions on the same vm
        def _get_driver(env)
          provider_config = env[:machine].provider_config 
          gateway = provider_config.gateway
          site = provider_config.site
          username = provider_config.username
          private_key = provider_config.private_key
          #key = "#{env[:machine].name}"
          key = "#{gateway}-#{site}-#{username}"
          options = {
            :forward_agent => true
          }
          options[:keys] = [private_key] if !private_key.nil?
          lockable(:lock => VagrantPlugins::G5K.g5k_lock) do
            if VagrantPlugins::G5K.pool[key].nil?
              @logger.debug "Creating a new session object for #{key}"
              if gateway.nil?
                @logger.debug("connecting with #{username} on site #{site}")
                session = Net::SSH.start(site, username, options)
              else
                @logger.debug("connecting with #{username} on site #{site} through #{gateway} with options #{options}")
                gateway = Net::SSH::Gateway.new(gateway, username, options)
                session = gateway.ssh(site, username, options)
              end
              VagrantPlugins::G5K.pool[key] = VagrantPlugins::G5K::Driver.new(session, Mutex.new)
            else
              @logger.debug "Reusing existing session for #{key}"
            end
          end
          return VagrantPlugins::G5K.pool[key]
        end

        def _get_net_driver(env, driver, oar_driver)
          net_type = env[:machine].provider_config.net[:type]
          if net_type == "bridge"
            klass = VagrantPlugins::G5K::Network::Bridge
          else
            klass = VagrantPlugins::G5K::Network::Nat
          end
          klass.new(env, driver, oar_driver)
        end

        def _get_disk_driver(env, cwd, driver)
          image = env[:machine].provider_config.image
          if image[:pool].nil?
            klass = VagrantPlugins::G5K::Disk::Local
          else
            klass = VagrantPlugins::G5K::Disk::RBD
          end
          klass.new(env, cwd, driver)
        end


      end
    end
  end
end
