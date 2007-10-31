

module Servers
    class CommunicationServer
        @@main_loop = nil
        
        # FIXME: Change this to start the service if is not already running, and drop the main loop
        def self.start()
            return unless @@main_loop == nil
            
#            begin
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
#            rescue DBus::Connection::NameRequestError => err
#                puts "Already running ..."
#            end
        end
        
        # FIXME: Change this to stop the service if it is running
        def self.stop
            @@main_loop.exit if @@main_loop
            @@main = @@main_loop = nil
        end
        
        def self.get_communicator
            start()
            
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
            
            dbus_method("setup_network", "in ip_address:s, in in_port:i, in out_port:i, in use_local_web_service:b, in on_error:s, out result:b") do |ip_address, in_port, out_port, use_local_web_service, on_error|
                raise "Already setup" if @is_setup
                
                # Make sure the on_error is valid
                on_error_options = [:log_to_file, :log_to_std_error, :throw]
                message = "The #{self.class.name} can only use #{on_error_options.join(', ')} for on_error in its start method."
                raise message unless on_error_options.include? on_error.to_sym
                @on_error = on_error
                
                # Save out web service connection type
                @use_local_web_service = use_local_web_service
            
            
                # Create a communication controller for routing DBus and Proxy communication over the Internet
                @communicator = Controllers::CommunicationController.new(ip_address, in_port, out_port)
                @generic_connection = @communicator.create_connection
                
                @is_setup = true
                
                [true]
            end
            
            dbus_method("ip_address", "out result:s") do
                [@communicator.ip_address]
            end
            
            dbus_method("in_port", "out result:i") do
                [@communicator.in_port]
            end
            
            dbus_method("out_port", "out result:i") do
                [@communicator.out_port]
            end
            
            dbus_method("on_error", "out result:s") do
                [@on_error.to_s]
            end
            
            dbus_method("use_local_web_service", "out result:b") do
                [@use_local_web_service]
            end
            
            #FIXME: We should return an as (array string) here, but dbus is broken
            dbus_method("create_network_connection", "out result:s") do
                c = @communicator.create_connection
                [c[:ip_address] + ":" + c[:port].to_s + ":" + c[:id].to_s]
            end
            
            dbus_method("destroy_network_connection", "in connection:s, out result:b") do |connection|
                @communicator.destroy_connection(YAML.load(connection))
                [true]
            end
            
            dbus_method("send_message", "in source_connection:s, in dest_connection:s, in message:s, out result:b") do |source_connection, dest_connection, message|
                source =
                if source_connection == :generic
                    @generic_connection
                else
                    YAML.load(source_connection)
                end
                @communicator.send(source,
                                    YAML.load(dest_connection),
                                     YAML.load(message))
                                     
                [true]
            end
            
            dbus_method("wait_for_message", "in connection:s, in message:s, out result:s") do |connection, message|
                source =
                if connection == :generic
                    @generic_connection
                else
                    YAML.load(connection)
                end
                result = @communicator.wait_for_command(connection,
                                              YAML.load(message))
                                              
                [YAML.dump(result)]
            end
            
            dbus_method("wait_for_any_message", "in connection:s, out result:s") do |connection|
                result = @communicator.wait_for_any_command(YAML.load(connection))
                                              
                [YAML.dump(result)]
            end
            
            private
            
            # Will return a reference to the web service
            def web_service
                unless @web_service
                    wsdl = 
                    if @use_local_web_service
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
        
        def run_project(revision_number, project_number, branch_number, document_server_connection, program)
            # Tell the Server that we want to run the project
            message = {:command => :run_project,
                        :project_number => project_number,
                        :branch_number => branch_number}
            send_message(:generic, document_server_connection, message)
        
            # Wait for the server to ok the process and give up a new connection to it
            message = wait_for_message(:generic, :ok_to_run_project)
            new_server_connection = message[:new_connection]
            
            # Confirm that we got the new server connection
            message = { :command => :confirm_new_connection }
            send_message(:generic, new_server_connection, message)
            
            # Get a new connection for the Model and Controller
            message = wait_for_message(:generic, :got_model_and_controller_connections)
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
        
        def setup_network(ip_address, in_port, out_port, use_local_web_service, on_error)
            @real_communication_server.setup_network(ip_address, in_port, out_port, use_local_web_service, on_error)
        end
        
        def ip_address
            @real_communication_server.ip_address
        end
            
        def in_port
            @real_communication_server.in_port
        end
            
        def out_port
            @real_communication_server.out_port
        end
            
        def on_error
            @real_communication_server.on_error
        end
            
        def use_local_web_service
            @real_communication_server.use_local_web_service
        end
        
        def create_network_connection
            c = @real_communication_server.create_network_connection.first
            { :ip_address => c.split(":")[0], :port => c.split(":")[1].to_i, :id => c.split(":")[2].to_i }
        end
        
        def destroy_network_connection(connection)
            @real_communication_server.destroy_network_connection(YAML.dump(connection))
        end
        
        def send_message(source_connection, dest_connection, message)
            source_connection = YAML.dump(msource_connectionessage) if source_connection != :generic
            
            @real_communication_server.send_message(
                                                 source_connection,
                                                 YAML.dump(dest_connection),
                                                 YAML.dump(message))
        end
        
        def wait_for_message(connection, message)
            connection = YAML.dump(connection) if connection != :generic
            
            result = @real_communication_server.wait_for_message(
                                                connection, 
                                                YAML.dump(message))
                                                
            YAML.load(result)
        end
        
        def wait_for_any_message(connection)
            result = @real_communication_server.wait_for_any_message( 
                                                YAML.dump(connection))
                                                
            YAML.load(result)
        end
    end
end

