

module Servers
    # FIXME: Change this to store the info in the dbus service instead of each memory space, to create a real service.
    class CommunicationServer    
        def self.start(ip_address, in_port, out_port, use_local_web_service = true, on_error = :log_to_file)            
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
            
            # Create a communication controller for routing DBus and Proxy communication over the Internet
            @@communicator = Controllers::CommunicationController.new(ip_address, in_port, out_port)
            @@network_connection = @@communicator.create_connection
            
            # Start the Dbus service main loop in a thread
            puts "Running Intuitive Desktop Communication Server"
            @@main_loop = Thread.new(bus) do |bus|
                @@main = DBus::Main.new
                @@main << bus
                @@main.run
            end
            @@main_loop.abort_on_exception = true
        end
        
        def self.ip_address
            @@communicator.ip_address
        end
        
        def self.in_port
            @@communicator.in_port
        end
        
        def self.out_port
            @@communicator.out_port
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
        
        def self.network_connection
            @@network_connection
        end
        
        def self.get_new_network_connection
            @@communicator.create_connection
        end
        
        def self.network_communicator
            @@communicator
        end
    end
    
    private
    
    # The class that holds all the methods to be accessed by the dbus object
    class CommunicationServerDBus < DBus::Object
        dbus_interface "org.intuitivedesktop.CommunicationServerInterface" do
            dbus_method("is_running", "out message:b") do
                [web_service.IsRunning()]
            end
            
            dbus_method("advertise_project_online", "in name:s, in description:s, in identity_public_key:s, in revision_number:i, in project_number:s, in branch_number:s, in ip_address:s, in port:i, in connection_id:i, out retval:b") do |name, description, identity_public_key, revision_number, project_number, branch_number, ip_address, port, connection_id|
                [web_service.RegisterProject(name, description, identity_public_key, revision_number, project_number, branch_number, ip_address, port, connection_id)]
            end
            
            dbus_method("search_for_projects_online", "in search:s, out results:aas") do |search|
                [web_service.SearchProjects(search)]
            end            
            
            dbus_method("run_project", "in revision_number:s, in project_number:s, in branch_number:s, in ip_address:s, in port:i, in connection_id:i, out results:b") do |revision_number, project_number, branch_number, ip_address, port, connection_id|
                [web_service.RunProject(revision_number, project_number, branch_number, ip_address, port, connection_id)]
            end
            
            dbus_method("clear_everything", "out result:b") do
                [web_service.EmptyEverything()]
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
                    begin
                        @web_service = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver
                    rescue
                        raise "Could not connect to web service at '#{wsdl}'."
                    end
                    raise "Could not connect to the web service at '#{wsdl}'." unless @web_service.IsRunning
                end
                
                return @web_service
            end
        end
    end
    
    # FIXME: Make this the new DataController. Trash the old one.
    # A class that wraps a CommunicationServerDBus
    class CommunicationServerWrapper
        def initialize(communicator)
            @real_communication_server = communicator         
        end
        
        def is_running
            @real_communication_server.is_running
        end
        
        def advertise_project_online(project)
            connection_id = CommunicationServer.get_new_network_connection[:id]
            
            @real_communication_server.advertise_project_online(
                                                        project.name, 
                                                        project.description, 
                                                        project.parent_branch.user_id, 
                                                        project.parent_branch.head_revision_number,
                                                        project.project_number.to_s,
                                                        project.parent_branch.branch_number.to_s,
                                                        CommunicationServer.ip_address,
                                                        CommunicationServer.in_port,
                                                        connection_id)
            
            return {:ip_address => CommunicationServer.ip_address,
              :port => CommunicationServer.in_port,
              :id => connection_id}
        end
        
        def search_for_projects_online(search)
            @real_communication_server.search_for_projects_online(search).first.collect do |p| 
                { :name => p[0], :description => p[1], 
                  :user_id => p[2], :revision => p[3].to_i, 
                  :project_number => p[4], :location => p[5] } 
            end
        end
        
        def run_project(revision_number, project_number, branch_number, document_server_connection)
            # Tell the Server that we want to run the project
            message = {:command => :run_project,
                        :project_number => project_number,
                        :branch_number => branch_number}
            CommunicationServer.network_communicator.send(CommunicationServer.network_connection, document_server_connection, message)
        
            # Wait for the server to ok the process and give up a new connection to it
            message = CommunicationServer.network_communicator.wait_for_command(CommunicationServer.network_connection, :ok_to_run_project)
            new_server_connection = message[:new_connection]
            
            # Confirm that we got the new server connection
            message = { :command => :confirm_new_connection }
            CommunicationServer.network_communicator.send(CommunicationServer.network_connection, new_server_connection, message)
            
            # Get a new connection for the Model and Controller
            message = CommunicationServer.network_communicator.wait_for_command(CommunicationServer.network_connection, :got_model_and_controller_connections)
            model_connections = message[:model_connections]
            main_controller_connection = message[:main_controller_connection]
            document_states = message[:document_states]
            document_views = message[:document_views]
            main_view_name = message[:main_view_name]
            
            # Create a proxy Models and Controller
            models = {}
            model_connections.each do |model_connection|
                model = Helpers::Proxy.get_proxy_to_object(CommunicationServer.network_communicator, model_connection)
                models[model.name] = model
            end
            
            controller = Helpers::Proxy.get_proxy_to_object(CommunicationServer.network_communicator, main_controller_connection)
            
            # Connect the Program to the Models and Controller
            program.models = models
            program.states = Models::Data::XmlModelCreator::models_from_documents(document_states)
            
            program.views = Views::View.views_from_documents(program, document_views)
            program.views.each do |name, view|
                program.main_view = view if name == main_view_name
            end
            
            program.main_controller = controller
            program.setup_bindings
        end
        
        def clear_everything
            @real_communication_server.clear_everything
        end
    end
end