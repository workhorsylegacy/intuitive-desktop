
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Namespace"

module ID; module Servers
	class IdentityServer
        def initialize(on_error)
            # Make sure the on_error is valid
            on_error_options = [:log_to_file, :log_to_std_error, :throw]
            message = "The Identity Server can only use #{on_error_options.join(', ')} for on_error."
            raise message unless on_error_options.include? on_error.to_sym
            @on_error = on_error
            
            # Determine if we are using the local or global web service
            wsdl = ID::Config.web_service
            
            # Connect to the web service
            message = "Could not connect to web service at '#{wsdl}'."
            begin
                @web_service = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver
            rescue
                raise message
            end
            raise message unless @web_service.IsRunning
            
            #@logger = Helpers::Logger.new(logger_output)
        end
        
        def close
        end
        
        def register_identity(name, description, public_key, private_key)
            encrypted_proof =
            @web_service.RegisterIdentityStart(name, 
                                              public_key,
                                              description, 
                                              ID::Config.ip_address,
                                              ID::Config.port, 
                                              0)

            decrypted_proof = Controllers::UserController::answer_ownership_test(private_key, encrypted_proof)
            
            @web_service.RegisterIdentityEnd(name, 
                                              public_key,
                                              description, 
                                              ID::Config.ip_address,
                                              ID::Config.port,
                                              0,
                                              decrypted_proof)
        end
        
        def find_identity(public_key)
            i = @web_service.FindIdentity(public_key)
            
            return {} if i.length == 0
            
            {:name => i[0], :public_key => i[1], :description => i[2],
             :ip_address => i[3], :port => i[4], :connection_id => i[5]}
        end
	end
end; end


