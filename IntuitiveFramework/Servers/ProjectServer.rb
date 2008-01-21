

module ID; module Servers
    # FIXME: Have this replace the DataController. Trash the old one.
    class ProjectServer
        def initialize(on_error)
            # Make sure the on_error is valid
            on_error_options = [:log_to_file, :log_to_std_error, :throw]
            message = "The Project Server can only use #{on_error_options.join(', ')} for on_error."
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
            
            # Create an internal Document Server for now
            #FIXME: Move the Document Server to be an item on the system that only uses the system communicator.
            # It should not be nested in here, but a separate service.
#            proc = Proc.new { |status, message, exception| raise message }
#            @document_server = Servers::DocumentServer.new("127.0.0.1", 5000, 6000, proc)
#            @document_server_connection = @document_server.instance_variable_get("@generic_net_connection")
        end
        
        def close
#            @system_communicator.close if @system_communicator
#            @net_communicator.close if @net_communicator
#            @system_communicator = nil
#            @net_communicator = nil
 #           @document_server.close if @document_server
 #           @document_server = nil
        end
    
        def is_running
            @web_service.IsRunning()
        end
            
        # FIXME: This should not be manual. Update when we add group permissions to the DataController
        def advertise_project_online(name, description, user_id, head_revision_number, project_number, branch_number)
            @web_service.RegisterProject(name, 
                                         description, 
                                         user_id, 
                                         head_revision_number,
                                         project_number,
                                         branch_number,
                                         ID::Config.ip_address,
                                              ID::Config.port, 
                                              0)
            
            nil
        end
            
        def search_for_projects_online(search)
            projects = @web_service.SearchProjects(search)
            projects.collect do |p|
                { :name => p[0], :description => p[1], 
                  :user_id => p[2], :revision => p[3].to_i, 
                  :project_number => p[4], :branch_number => p[5],
                  :ip_address => p[6], :port => p[7], :connection_id => p[8] }
            end
        end
            
        def self.run_project(project_connection,
                             revision, project_number,
                                        branch_number,
                                        program) 
                                        
            communicator = Controllers::CommunicationController.new(:name => :random)
            
            # Tell the Server that we want to run the project
            message = {:command => :run_project,
                        :project_number => project_number,
                        :branch_number => branch_number}
            communicator.send_command(project_connection, message)
        
            # Wait for the server to ok the process and give up a new connection to it
            communicator.get_command(project_connection, :ok_to_run_project) do |message|
                new_server_connection = message[:new_connection]
                
                # Confirm that we got the new server connection
                message = { :command => :confirm_new_connection }
                communicator.send_command(project_connection, message)
            end
            
            # Get a new connection for the Model and Controller
            model_connections, main_controller_connection, 
            document_states, document_views, main_view_name = nil
                
            communicator.get_command(:got_model_and_controller_connections) do |message|
                model_connections = message[:model_connections]
                main_controller_connection = message[:main_controller_connection]
                document_states = message[:document_states]
                document_views = message[:document_views]
                main_view_name = message[:main_view_name]
            end
            
            communicator.close
            
            # Create a proxy Models and Controller
            models = {}
            model_connections.each do |model_connection|
                model = Helpers::Proxy.get_proxy_to_object(model_connection)
                models[model.name] = model
            end
            
            controller = Helpers::Proxy.get_proxy_to_object(main_controller_connection)
            
            # Connect the Program to the Models and Controller
            program.models = models
            program.states = Models::Data::XmlModelCreator::models_from_documents(document_states)
            
            program.views = Views::View.views_from_documents(program, document_views)
            program.views.each do |name, view|
                program.main_view = view if name == main_view_name
            end
            
            program.main_controller = controller
            program.setup_bindings
            
            nil
        end
            
        def clear_everything
            @web_service.EmptyEverything()
        end
            
        def on_error
            @on_error.to_s
        end
    end
end; end


