
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Namespace"

module ID; module Servers
	class IdentityServer
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
        end
        
        def close
        end
        
        def register_identity(name, description, public_key, private_key)
            raise "We need a way to get the com server's info here. This needs to work transparently in debug or production mode too. Have it use a yaml config file, and use $DEBUG?"
            encrypted_proof =
            @web_service.RegisterIdentityStart(name, 
                                              public_key,
                                              description, 
                                              ID::Config.Ip_address,
                                              ID::Config.port)

            decrypted_proof = Controllers::UserController::answer_ownership_test(private_key, encrypted_proof)
            
            @web_service.RegisterIdentityEnd(name, 
                                              public_key,
                                              description, 
                                              ID::Config.ip_address,
                                              ID::Config.port,
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


