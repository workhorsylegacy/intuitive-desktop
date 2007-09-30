
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Namespace"

require 'pathname'

module Helpers
	class Proxy        
        def self.make_object_proxyable(object_to_serve, communicator, proxy_timeout=60)
            connection = communicator.create_connection
            
            # Perform any calls to the Object from the communicator
            proxy_thread = Thread.new(object_to_serve, communicator, connection) {|object, commun, connec|
                    # Create a thread to timeout the proxy connection
                    timout_thread = nil
                    timout_thread = reset_timeout_thread(timout_thread, proxy_thread, proxy_timeout)
            
                    loop do
                        commun.wait_for_any_command(connec) {|message|
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
                                    end
                                    
                                    # Return any result and exceptions
                                    message = {:command => :send_to_object_return_value,
                                                :return_value => retval,
                                                :exception => exception,
                                                :exception_class_name => exception_class_name}
                                    commun.send(connec, remote_connection, message)
                                when :proxy_still_alive
                                    timout_thread = reset_timeout_thread(timout_thread, proxy_thread, proxy_timeout)
                                    message = { :command => :will_stay_alive }
                                    commun.send(connec, remote_connection, message)                                    
                                else
                                    error = "The proxied object does not know what to do with the command '#{message[:command]}'."
                                    message = {:command => :send_to_object_return_value,
                                                :return_value => retval,
                                                :exception => Exception.new(error),
                                                :exception_class_name => Exception}
                                    commun.send(connec, remote_connection, message)
                            end
                        }
                    end
            }
            
            connection
        end
		
		def self.get_proxy_to_object(communicator, server_connection, proxy_timeout=50)
		    proxy = Object.new
		    local_connection = communicator.create_connection
		    
		    # Save the connection info in instance variables
		    proxy.instance_variable_set('@proxy_communicator', communicator)
		    proxy.instance_variable_set('@proxy_local_connection', local_connection)
		    proxy.instance_variable_set('@proxy_server_connection', server_connection)
		    
            def proxy.method_missing(name, *args)
                Helpers::Proxy.call_object(@proxy_communicator, @proxy_local_connection, @proxy_server_connection, name, args)
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
		    
#		    # Convert the class name to the actual class
#		    def proxy.class
#		        class_name = method_missing('class')
#		        
#		        begin
#		            eval(class_name)
#		        rescue NameError => e
#		            raise "The proxy cannot use the real object's class '#{class_name}' because the class is not known in the proxies ObjectSpace."
#		        end
#		    end
		    
		    # Create thread that tells real object to stay alive
		    proxy_alive_thread = Thread.new(communicator, local_connection, server_connection) do |commun, local_conn, remote_conn|
		        loop do
		            sleep proxy_timeout
		            
		            message = { :command => :proxy_still_alive }
		            commun.send(local_conn, remote_conn, message)
		            
		            commun.wait_for_command(local_conn, :will_stay_alive)
		        end
		    end		    
		    
		    # Stop telling the real object to live when the proxy is GCed
		    ObjectSpace.define_finalizer(proxy) do
		        proxy_alive_thread.terminate if proxy_alive_thread
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
                communicator.send(local_connection, server_connection, message)
    
                # Get the return value of the call
                message = communicator.wait_for_command(local_connection, :send_to_object_return_value)
                    
                # raise an error if the object on the Server threw
                raise eval(message[:exception_class_name]), message[:exception] if message[:exception] && message[:exception_class_name]

                return message[:return_value]
    		rescue NameError => e
    		    # Turn any NameError into an Exception to stop infinite method_missing loop
    			raise Exception, e.message
    		end
        end
	end
end
