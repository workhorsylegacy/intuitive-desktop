
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Namespace"

require 'pathname'

module Helpers
    class ProxiedException < Exception
        attr_reader :backtrace, :message
    
        def initialize(message, backtrace)
            # Create a local backtrace and include it with the remote backtrace
            local_error = nil
            begin
                raise ""
            rescue Exception => e
                local_error = e
            end
        
            @message = message
            @backtrace = ["==== Remote backtrace ===="] + backtrace +
                          ["==== Local backtrace ===="] + local_error.backtrace[1..-1]
        end
    end
end

# FIXME: Rename to NetProxy
module Helpers
	class Proxy
        def self.make_object_proxyable(object_to_serve, proxy_timeout=60)
            communication_server = Helpers::SystemProxy.get_proxy_to_object("CommunicationServer")
            connection = communication_server.create_net_connection()
            
            # Add a method for testing the connection
            def object_to_serve.is_proxy_connected?
                true
            end            
            
            # Perform any calls to the Object from the communicator
            proxy_thread = Thread.new(object_to_serve, communication_server, connection) do |object, commun, connec|
                    # Create a thread to timeout the proxy connection
                    timout_thread = nil
                    timout_thread = reset_timeout_thread(timout_thread, proxy_thread, proxy_timeout)
            
                    loop do
                            message = nil
                            while (message = commun.get_any_net_message(connec)) == nil
                                sleep 0.1
                            end
                            remote_connection = message[:source_connection]
                            
                            case message[:command]
                                when :send_to_object
                                    name = message[:name]
                                    args = message[:args].first
                                    retval = nil
                                    exception = nil
                                    exception_class_name = nil
                                    
                                    # Try to call the method
                                    begin
                                        raise NameError, "The method .method cannot be used with a proxy." if name == 'method'
                                        raise NameError, "The method .class cannot be used with a proxy." if name == 'class' && args.length == 0
                                        
                                        retval = object.send(name, *args)
                                    rescue Exception => e
                                        exception = e.message
                                        exception_class_name = e.class.name
                                        exception_backtrace = e.backtrace
                                    end
                                    
                                    # Return any result and exceptions
                                    message = {:command => :send_to_object_return_value,
                                                :return_value => retval,
                                                :exception => exception,
                                                :exception_class_name => exception_class_name,
                                                :backtrace => exception_backtrace}
                                    commun.send_net_message(connec, remote_connection, message)
                                when :proxy_still_alive
                                    timout_thread = reset_timeout_thread(timout_thread, proxy_thread, proxy_timeout)
                                    message = { :command => :will_stay_alive }
                                    commun.send_net_message(connec, remote_connection, message)                                    
                                else
                                    error = "The proxied object does not know what to do with the command '#{message[:command]}'."
                                    message = {:command => :send_to_object_return_value,
                                                :return_value => retval,
                                                :exception => Exception.new(error),
                                                :exception_class_name => Exception}
                                    commun.send_net_message(connec, remote_connection, message)
                            end
                    end
            end
            
            # Have the communicator close when the object to serve is GCed
            ObjectSpace.define_finalizer(object_to_serve) do
                communication_server.delete_net_connection(connection) if communication_server && connection
            end            
            
            connection
        end
		
		def self.get_proxy_to_object(server_connection, proxy_timeout=50)
        communication_server = Helpers::SystemProxy.get_proxy_to_object("CommunicationServer")
        connection = communication_server.create_net_connection()
    
		    proxy = Object.new
		    
		    # Save the connection info in instance variables
		    proxy.instance_variable_set('@proxy_communicator', communication_server)
		    proxy.instance_variable_set('@proxy_local_connection', connection)
		    proxy.instance_variable_set('@proxy_server_connection', server_connection)
		    
            def proxy.method_missing(name, *args)
                Helpers::Proxy.call_object(@proxy_communicator, @proxy_local_connection, @proxy_server_connection, name, args)
            end
		    
          def proxy.is_proxy_connected?
              false
          end        
        
            # Get a list of methods to replace
            replaceable_methods = proxy.methods.sort - ['class', 'method_missing'] << 'class'
            
            # Remove all the default methods so they will be proxied to the real object
    		replaceable_methods.each do |method_name|
    			eval(
    			"def proxy.#{method_name}(*args) \
    				method_missing('#{method_name}', *args) \
    			end")
    		end
		    
		    # Create thread that tells real object to stay alive
		    proxy_alive_thread = Thread.new(communication_server, connection, server_connection) do |commun, local_conn, remote_conn|
		        loop do
		            sleep proxy_timeout
		            
		            message = { :command => :proxy_still_alive }
		            commun.send_net_message(local_conn, remote_conn, message)
		            
		            while commun.get_net_message(local_conn, :will_stay_alive) == nil
                    sleep 1
                end
		        end
		    end		    
		    
		    # Stop telling the real object to live when the proxy is GCed
		    ObjectSpace.define_finalizer(proxy) do
            communication_server.destroy_net_connection(connection) if communication_server && connection
		        proxy_alive_thread.terminate if proxy_alive_thread
		    end
		    
        # Make sure there is something to connect to
        begin
            proxy.is_proxy_connected?
        rescue
            raise "No object named '#{name}' to connect to."
        end        
        
		    proxy
		end
		
		private
		def self.reset_timeout_thread(timeout_thread, proxy_thread, proxy_timeout)
            timeout_thread.exit if timeout_thread
            
            timeout_thread = Thread.new(proxy_thread) do |proxy_thread|
                sleep proxy_timeout
                proxy_thread.exit
            end
            
            timeout_thread
		end
		
        def self.call_object(communicator, local_connection, server_connection, name, *args)
        	begin
                # Forward the method call to the object on the Server
                message = { :command => :send_to_object,
                                    :name => name,
                                    :args => args }
                communicator.send_net_message(local_connection, server_connection, message)
    
                # Get the return value of the call
                message = nil
                while (message = communicator.get_net_message(local_connection, :send_to_object_return_value)) == nil
                    sleep 0.1
                end
                    
                # raise an error if the object on the Server threw
                if message[:exception]
                    raise Helpers::ProxiedException.new(message[:exception], message[:backtrace])
                end

                return message[:return_value]
    		rescue NameError => e
    		    # Turn any NameError into an Exception to stop infinite method_missing loop
    			raise Exception, e.message
    		end
        end
	end
end
