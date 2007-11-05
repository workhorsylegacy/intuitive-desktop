

module Servers
    # FIXME: Have this replace the DataController. Trash the old one.
    class CommunicationServer
        
        def self.force_kill_other_instances
            return unless Controllers::SystemCommunicationController.is_name_used?("CommunicationServer")
            
            unix_socket_file = Controllers::SystemCommunicationController.get_socket_file_name("CommunicationServer")
            File.delete(unix_socket_file)
        end
        
        def initialize(ip_address, in_port, out_port, use_local_web_service, on_error)
            # Make sure the on_error is valid
            on_error_options = [:log_to_file, :log_to_std_error, :throw]
            message = "The Communication Server can only use #{on_error_options.join(', ')} for on_error."
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
                    
            # Create the net communicator
            @net_communicator = Controllers::CommunicationController.new(ip_address, in_port, out_port)
            @generic_net_connection = @net_communicator.create_connection
                    
            # Create the system communicator
            if Controllers::SystemCommunicationController.is_name_used?("CommunicationServer")
                raise "The Communication Server is already running."
            else
                @system_communicator = Controllers::SystemCommunicationController.new("CommunicationServer")
            end
        end
        
        def close
            @system_communicator.close if @system_communicator
            @system_communicator = nil
        end
    
        def is_running
            @web_service.IsRunning()
        end
            
        def advertise_project_online(project)

            connection = create_net_connection
            
            @web_service.RegisterProject(
                                         project.name, 
                                         project.description, 
                                         project.parent_branch.user_id, 
                                         project.parent_branch.head_revision_number,
                                         project.project_number.to_s,
                                         project.parent_branch.branch_number.to_s,
                                         connection[:ip_address],
                                         connection[:in_port],
                                         connection[:id])
            
            connection
        end
            
        def search_for_projects_online(search)
            p = @web_service.SearchProjects(search)
            
            { :name => p[0], :description => p[1], 
              :user_id => p[2], :revision => p[3].to_i, 
              :project_number => p[4], :location => p[5] }
        end            
            
        def send_message(source_connection, dest_connection, message)
            source =
            if source_connection == :generic
                @generic_connection
            else
                source_connection
            end
            @net_communicator.send(source,
                               dest_connection,
                               message)
                                     
            nil
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
            
            nil
        end
            
        def clear_everything
            @web_service.EmptyEverything()
        end
            
        def ip_address
            @net_communicator.ip_address
        end
            
        def in_port
            @net_communicator.in_port
        end
            
        def out_port
            @net_communicator.out_port
        end
            
        def on_error
            @on_error.to_s
        end
            
        def use_local_web_service
            @use_local_web_service
        end
            
        def create_net_connection
            @net_communicator.create_connection
        end
            
        def destroy_net_connection(connection)
            @net_communicator.destroy_connection(connection)
        end
            
        def wait_for_message(connection, message)
            source =
            if connection == :generic
                @generic_connection
            else
                connection
            end
            @net_communicator.wait_for_command(connection, message)
        end
            
        def wait_for_any_message(connection)
            @net_communicator.wait_for_any_command(connection)
        end
    end
end

