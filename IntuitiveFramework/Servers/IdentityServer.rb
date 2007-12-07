
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Namespace"

module Servers
	class IdentityServer
        def self.force_kill_other_instances
            return unless Controllers::SystemCommunicationController.is_name_used?("IdentityServer")
            
            unix_socket_file = Controllers::SystemCommunicationController.get_socket_file_name("IdentityServer")
            File.delete(unix_socket_file) if File.exist?(unix_socket_file)
        end
        
        def initialize(use_local_web_service, on_error)
            # Make sure the on_error is valid
            on_error_options = [:log_to_file, :log_to_std_error, :throw]
            message = "The Identity Server can only use #{on_error_options.join(', ')} for on_error."
            raise message unless on_error_options.include? on_error.to_sym
            @on_error = on_error
            
            # Save the web service connection type
            @use_local_web_service = use_local_web_service
            
            # Determine if we are using the local or global web service
            wsdl = 
            if @use_local_web_service
                "http://localhost:3000/projects/service.wsdl"
            else
                "http://service.intuitive-desktop.org/projects/service.wsdl"
            end
            
            # Connect to the web service
            begin
                @web_service = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver
            rescue
                raise "Could not connect to web service at '#{wsdl}'."
            end
            raise "Could not connect to the web service at '#{wsdl}'." unless @web_service.IsRunning
            
            #@logger = Helpers::Logger.new(logger_output)
            
            # Make the server available over the system communicator
            Helpers::SystemProxy.make_object_proxyable(self, "IdentityServer")
        end
        
        def close
        end
        
        def register_identity(connection, name, description, user_id)
            @web_service.RegisterIdentityStart(name, 
                                              user_id,
                                              description, 
                                              connection[:ip_address],
                                              connection[:port],
                                              connection[:id])
                                              
            decrypted_proof = answer_ownership_test(private_key, encrypted_proof)
            
            @web_service.RegisterIdentityEnd(name, 
                                              user_id,
                                              description, 
                                              connection[:ip_address],
                                              connection[:port],
                                              connection[:id],
                                              decrypted_proof)
        end
        
        def has_identity?(public_key)
            @identities.has_key?(public_key)
        end
	end
end

