

module Servers
    # FIXME: Have this replace the DataController. Trash the old one.
    class ProjectServer
        def self.force_kill_other_instances
            return unless Controllers::SystemCommunicationController.is_name_used?("ProjectServer")
            
            unix_socket_file = Controllers::SystemCommunicationController.get_socket_file_name("ProjectServer")
            File.delete(unix_socket_file)
        end
        
        def initialize(use_local_web_service, on_error)
            # Make sure the on_error is valid
            on_error_options = [:log_to_file, :log_to_std_error, :throw]
            message = "The Project Server can only use #{on_error_options.join(', ')} for on_error."
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
            
            # Create an internal Document Server for now
            #FIXME: Move the Document Server to be an item on the system that only uses the system communicator.
            # It should not be nested in here, but a separate service.
            proc = Proc.new { |status, message, exception| raise message }
#            @document_server = Servers::DocumentServer.new("127.0.0.1", 5000, 6000, proc)
#            @document_server_connection = @document_server.instance_variable_get("@generic_net_connection")
            
            # Make the server available over the system communicator
            Helpers::SystemProxy.make_object_proxyable(self, "ProjectServer")
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
            
        def advertise_project_online(project)

            communication_server = Helpers::SystemProxy.get_proxy_to_object("DocumentServer")
            connection = communication_server.get_generic_external_connection()

            @web_service.RegisterProject(
                                         project.name, 
                                         project.description, 
                                         project.parent_branch.user_id, 
                                         project.parent_branch.head_revision_number,
                                         project.project_number.to_s,
                                         project.parent_branch.branch_number.to_s,
                                         connection[:ip_address],
                                         connection[:port],
                                         connection[:id])
            
            nil
        end
            
        def search_for_projects_online(search)
            projects = @web_service.SearchProjects(search)
            projects.collect do |p|
                { :name => p[0], :description => p[1], 
                  :user_id => p[2], :revision => p[3].to_i, 
                  :project_number => p[4], :location => p[5] }
            end
        end
            
        def self.run_project(revision_number, project_number, branch_number, program)
            document_server_connection = communication_server.instance_variable_get("@document_server_connection")
            
            # Tell the Server that we want to run the project
            message = {:command => :run_project,
                        :project_number => project_number,
                        :branch_number => branch_number}
            communication_server.send_message(:generic, document_server_connection, message)
        
            # Wait for the server to ok the process and give up a new connection to it
            message = communication_server.wait_for_message(:generic, :ok_to_run_project)
            new_server_connection = message[:new_connection]
            
            # Confirm that we got the new server connection
            message = { :command => :confirm_new_connection }
            communication_server.send_message(:generic, new_server_connection, message)
            
            # Get a new connection for the Model and Controller
            message = communication_server.wait_for_message(:generic, :got_model_and_controller_connections)
            model_connections = message[:model_connections]
            main_controller_connection = message[:main_controller_connection]
            document_states = message[:document_states]
            document_views = message[:document_views]
            main_view_name = message[:main_view_name]
            
            # Create a proxy Models and Controller
            models = {}
            model_connections.each do |model_connection|
                model = Helpers::Proxy.get_proxy_to_object(communication_server.net_communicator, model_connection)
                models[model.name] = model
            end
            
            controller = Helpers::Proxy.get_proxy_to_object(communication_server.net_communicator, main_controller_connection)
            
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
            
        def use_local_web_service
            @use_local_web_service
        end
    end
end

