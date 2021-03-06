
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
            
            # Add a method for testing the connection
            object_to_serve = args[:object]
            def object_to_serve.is_proxy_connected?
                true
            end            
            
            communicator = Controllers::CommunicationController.new(args[:name])
            
            # Perform any calls to the Object from the communicator
            proxy_thread = Thread.new do
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
                                           :destination => source,
                                           :return_value => retval,
                                           :exception => exception,
                                           :exception_class_name => exception_class_name,
                                           :backtrace => exception_backtrace}
                                communicator.send_command(message)
                            else
                                error = "The proxied object does not know what to do with the command '#{message[:command]}'."
                                message = {:command => :return,
                                           :destination => source,
                                           :return_value => retval,
                                           :exception => Exception.new(error),
                                           :exception_class_name => Exception}
                                communicator.send_command(message)
                        end
                    end
                end
            end
            
            # Have the communicator close when the object to serve is GCed
            ObjectSpace.define_finalizer(object_to_serve) do
                communicator.close if communicator
                proxy_thread.kill if proxy_thread
            end

            communicator.full_address
        end
		
		def self.get_proxy_to_object(args)
            # Make sure the arguments are valid
            raise "The argument must be a hash." unless args.is_a? Hash
            raise "The argument 'name' is missing." unless args[:name]
            
        communicator = Controllers::CommunicationController.new(:random)
		    proxy = Object.new
		    
		    # Save the connection info in instance variables
        proxy_address = {}
        proxy_address.merge! :name => args[:name]
        proxy_address.merge! :ip_address => args[:ip_address] if args.has_key? :ip_address
        proxy_address.merge! :port => args[:port] if args.has_key? :port
		    proxy.instance_variable_set('@proxy_communicator', communicator)
		    proxy.instance_variable_set('@proxy_address', proxy_address)
		    
            def proxy.method_missing(name, *args)
                Helpers::Proxy.call_object(@proxy_communicator, @proxy_address, name, args)
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
            raise "No object named '#{args[:name]}' to connect to."
        end        
        
		    proxy
		end
		
		private
		
        def self.call_object(communicator, proxy_address, method_name, *args)
        	begin
                # Forward the method call to the object on the Server
                message = { :command => :send_to_object,
                            :destination => proxy_address,
                                    :name => method_name,
                                    :args => args }
                communicator.send_command(message)
    
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
