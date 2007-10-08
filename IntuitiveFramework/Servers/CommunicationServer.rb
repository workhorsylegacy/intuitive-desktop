

module Servers
    class CommunicationServer
        def self.start(use_local_web_service = true, on_error = :log_to_file)
            # Make sure the on_error is valid
            valid_on_error = [:log_to_file, :log_to_std_error, :throw]
            message = "The #{self.class.name} can only use #{valid_on_error.join(', ')} for on_error in its start method."
            raise message unless valid_on_error.include? on_error
            @@on_error = on_error
            
            # Save out web service connection type
            @@use_local_web_service = use_local_web_service
            
            # Create the Dbus service
            bus = DBus::SessionBus.instance
            service = bus.request_service("org.intuitivedesktop.service")
            communication_server = CommunicationServerDBus.new("/org/intuitivedesktop/CommunicationServer")
            service.export(communication_server)
            
            # Start the Dbus service main loop in a thread
            puts "Running Intuitive Desktop Communication Server"
            @@main_loop = Thread.new(bus) do |bus|
                @@main = DBus::Main.new
                @@main << bus
                @@main.run
            end
            @@main_loop.abort_on_exception = true
        end
        
        def self.stop
            @@main_loop.exit if @@main_loop
            @@main = @@main_loop = nil
        end
        
        def self.on_error
            @@on_error
        end
        
        def self.use_local_web_service
            @@use_local_web_service
        end
        
        def self.get_communicator
            session_bus = DBus::SessionBus.instance
            
            # Get the Intuitive-Desktop service
            ruby_srv = session_bus.service("org.intuitivedesktop.service")
            
            # Get the object from this service
            communicator = ruby_srv.object("/org/intuitivedesktop/CommunicationServer")
            
            # Connect the object to the service
            communicator.introspect
            communicator.default_iface = "org.intuitivedesktop.CommunicationServerInterface"
            
            # Return the wrapped communicator
            return CommunicationServerWrapper.new(communicator)
        end
    end
    
    private
    
    # The class that holds all the methods to be accessed by the dbus object
    class CommunicationServerDBus < DBus::Object
        dbus_interface "org.intuitivedesktop.CommunicationServerInterface" do
            dbus_method "is_running", "out message:b" do
                [true]
            end
            
            dbus_method("advertise_project_online", "in name:s, in description:s, in identity_public_key:s, in revision_number:i, out retval:b") do |name, description, identity_public_key, revision_number|
                retval = web_service.RegisterProject(name, description, identity_public_key, revision_number)
                [retval]
            end
            
            dbus_method("search_for_projects_online", "in search:s, out results:ss") do |search|
                [web_service.SearchProjects(search)]
            end            
            
            # Will return a reference to the web service
            def web_service
                unless @web_service
                    wsdl = 
                    if Servers::CommunicationServer.use_local_web_service
                        "http://localhost:3000/projects/service.wsdl"
                    else
                        "http://service.intuitive-desktop.org/projects/service.wsdl"
                    end
                    @web_service = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver
                    raise "Could not connect to the web service at '#{wsdl}'." unless @web_service.IsRunning
                end
                
                return @web_service
            end
        end
    end
    
    # A class that wraps a CommunicationServerDBus
    class CommunicationServerWrapper
        def initialize(communicator)
            @real_communication_server = communicator         
        end
        
        def is_running
            @real_communication_server.is_running
        end
        
        def advertise_project_online(project)
            @real_communication_server.advertise_project_online(project.name, project.description, project.parent_branch.user_id, project.parent_branch.head_revision_number)
        end
        
        def search_for_projects_online(search)
            @real_communication_server.search_for_projects_online(search)
        end
    end
end