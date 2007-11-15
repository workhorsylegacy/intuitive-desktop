
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Namespace"

require 'pathname'

module Helpers
  class SystemProxy        
        def self.make_object_proxyable(object_to_serve, name=:random, proxy_timeout=60)
            communicator = Controllers::SystemCommunicationController.new(name)
            
            # Add a method for testing the connection
            def object_to_serve.is_proxy_connected?
                true
            end
            
            # Perform any calls to the Object from the communicator
            proxy_thread = Thread.new(object_to_serve, communicator) do |object, commun|
                    # Create a thread to timeout the proxy connection
                    timout_thread = nil
                    timout_thread = reset_timeout_thread(timout_thread, proxy_thread, proxy_timeout)
            
                    loop do
                        commun.wait_for_any_command do |message|
                            puts "SystemProxy got: #{message.inspect}."
                            remote_connection = message[:source_connection]
                            
                            case message[:command]
                                when :send_to_object
                                    name = message[:name]
                                    args = message[:args].first
                                    retval = nil
                                    exception = nil
                                    exception_class_name = nil
                                    exception_backtrace = nil
                                    
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
                                    commun.send_command(remote_connection, message)
                                when :proxy_still_alive
                                    timout_thread = reset_timeout_thread(timout_thread, proxy_thread, proxy_timeout)
                                    message = { :command => :will_stay_alive }
                                    commun.send_command(remote_connection, message)                                    
                                else
                                    error = "The proxied object does not know what to do with the command '#{message[:command]}'."
                                    message = {:command => :send_to_object_return_value,
                                                :return_value => retval,
                                                :exception => Exception.new(error),
                                                :exception_class_name => Exception}
                                    commun.send_command(remote_connection, message)
                            end
                        end
                    end
            end
            
            # Have the communicator close when the object to serve is GCed
            ObjectSpace.define_finalizer(object_to_serve) do
                communicator.close if communicator
            end
            
            nil
        end
    
    def self.get_proxy_to_object(name, proxy_timeout=50)
        communicator = Controllers::SystemCommunicationController.new()

        # Save the connection info in instance variables
        proxy = Object.new
        proxy.instance_variable_set('@proxy_communicator', communicator)
        proxy.instance_variable_set('@proxy_server_name', name)
        
        def proxy.method_missing(name, *args)
            Helpers::SystemProxy.call_object(@proxy_communicator, @proxy_server_name, name, args)
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
        
        # Create thread that tells the real object to stay alive
        proxy_alive_thread = Thread.new(communicator, name) do |commun, name|
            loop do
                sleep proxy_timeout
                
                message = { :command => :proxy_still_alive }
                commun.send_command(name, message)
                
                commun.wait_for_command(:will_stay_alive)
            end
        end       
        
        # Stop telling the real object to live when the proxy is GCed
        ObjectSpace.define_finalizer(proxy) do
            communicator.close if communicator
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
    
        def self.call_object(communicator, server_name, name, *args)
          begin
                # Forward the method call to the object on the Server
                message = { :command => :send_to_object,
                                    :name => name,
                                    :args => args }
                communicator.send_command(server_name, message)
                puts "SystemProxy set: #{message.inspect}."
    
                # Get the return value of the call
                message = communicator.wait_for_command(:send_to_object_return_value)
                    
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
