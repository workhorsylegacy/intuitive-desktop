
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Namespace"

require 'pathname'

module ID; module Helpers
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

module Helpers
    class Proxy
        def self.make_object_proxyable(args)
            # Make sure the arguments are valid
            raise "The argument must be a hash." unless args.is_a? Hash
            raise "The argument 'object' is missing." unless args[:object]
            raise "The argument 'name' is missing." unless args[:name]
            raise "The argument 'type' is missing." unless args[:type]
            
            # Add a method for testing the connection
            object_to_serve = args[:object]
            def object_to_serve.is_proxy_connected?
                true
            end            
            
            # Perform any calls to the Object from the communicator
            proxy_thread = Thread.new do
                communicator = Controllers::CommunicationController.new(args)
                
                loop do
                    communicator.wait_for_any_command do |message|
                        source = message[:source]
                                
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
                                    raise NameError, "The method .class cannot be used with a proxy." if name == 'class'
                                            
                                    retval = object_to_serve.send(name, *args)
                                rescue Exception => e
                                    exception = e.message
                                    exception_class_name = e.class.name
                                    exception_backtrace = e.backtrace
                                end
                                        
                                # Return any result and exceptions
                                message = {:command => :return,
                                           :return_value => retval,
                                           :exception => exception,
                                           :exception_class_name => exception_class_name,
                                           :backtrace => exception_backtrace}
                                communicator.send_command(source, message)
                            else
                                error = "The proxied object does not know what to do with the command '#{message[:command]}'."
                                message = {:command => :return,
                                           :return_value => retval,
                                           :exception => Exception.new(error),
                                           :exception_class_name => Exception}
                                communicator.send_command(source, message)
                        end
                    end
                end
            end
            
            # Have the communicator close when the object to serve is GCed
            ObjectSpace.define_finalizer(object_to_serve) do
                communicator.close if communicator
                proxy_thread.kill if proxy_thread
            end

            nil
        end
		
		def self.get_proxy_to_object(args)
            # Make sure the arguments are valid
            raise "The argument must be a hash." unless args.is_a? Hash
            raise "The argument 'name' is missing." unless args[:name]
            raise "The argument 'type' is missing." unless args[:type]
            
        communicator = Controllers::CommunicationController.new(:name => :random, :type => args[:type])
		    proxy = Object.new
		    
		    # Save the connection info in instance variables
		    proxy.instance_variable_set('@proxy_communicator', communicator)
		    proxy.instance_variable_set('@proxy_name', "#{args[:name]}:#{args[:type]}")
		    
            def proxy.method_missing(name, *args)
                Helpers::Proxy.call_object(@proxy_communicator, @proxy_name, name, args)
            end
		    
          def proxy.is_proxy_connected?
              false
          end        
        
            # Get a list of methods to replace
            replaceable_methods = proxy.methods.sort - ['class', 'method_missing'] << 'class' # Make .class last in the list
            
            # Remove all the default methods so they will be proxied to the real object
    		replaceable_methods.each do |method_name|
    			eval(
    			"def proxy.#{method_name}(*args) \
    				method_missing('#{method_name}', *args) \
    			end")
    		end
		    
        # Make sure there is something to connect to
        begin
            proxy.is_proxy_connected?
        rescue
            raise "No object named '#{args[:name]}:#{args[:type]}' to connect to."
        end        
        
		    proxy
		end
		
		private
		
        def self.call_object(communicator, object_name, method_name, *args)
        	begin
                # Forward the method call to the object on the Server
                message = { :command => :send_to_object,
                                    :name => method_name,
                                    :args => args }
                communicator.send_command(object_name, message)
    
                # Get the return value of the call
                communicator.wait_for_command(:return) do |message|
                    # raise an error if the object on the Server threw
                    if message[:exception]
                        raise Helpers::ProxiedException.new(message[:exception], message[:backtrace])
                    end
    
                    return message[:return_value]
                end
    		rescue NameError => e
    		    # Turn any NameError into an Exception to stop infinite method_missing loop
    			raise Exception, e.message
    		end
        end
	end
end; end
