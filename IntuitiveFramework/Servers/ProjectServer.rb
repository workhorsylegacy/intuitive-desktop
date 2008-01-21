

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
            
            # Start the communication thread
            self.open
        end
        
        def close
            @is_open = false
            
            @communicator.close if @communicator
            @communicator = nil
            @in_thread.kill if @in_thread
            @in_thread = nil
        end
    
        def open
            @communicator = Controllers::CommunicationController.new("ProjectServer")
            
            @is_open = true
            @in_thread = Thread.new do
                while @is_open
                    @communicator.wait_for_any_command do |message|
                        case message[:command]
                            when :run_project: run_project_request(message)
                        end
                    end
                end
            end
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
           
        def net_address
            # FIXME: This will just be localhost for now
            {:name => @communicator.name,
             :ip_address => ID::Config.ip_address,
             :port => ID::Config.port}
        end
            
        def self.run_project(server_address,
                             revision, project_number,
                                        branch_number,
                                        program) 
                                        
            communicator = Controllers::CommunicationController.new(:random)
            
            # Tell the Server that we want to run the project
            message = {:command => :run_project,
                        :project_number => project_number,
                        :branch_number => branch_number,
                        :destination => server_address}
            communicator.send_command(message)
        
            # Wait for the server to ok the process and give up a new connection to it
            communicator.wait_for_command(:ok_to_run_project) do |message|
                new_server_connection = message[:new_connection]
                
                # Confirm that we got the new server connection
                message = { :command => :confirm_new_connection,
                             :destination => new_server_connection }
                communicator.send_command(message)
            end
            
            # Get a new connection for the Model and Controller
            model_connections, main_controller_connection, 
            document_states, document_views, main_view_name = nil
                
            communicator.wait_for_command(:got_model_and_controller_connections) do |message|
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
        
        private
        
        def run_project_request(message)
            # Get the information
            remote_connection = message[:source]
            project_number = message[:project_number]
            branch_number = message[:branch_number]

            # Create another communicator just for this conversation and tell the remote machine to use it
            temp_communicator = Controllers::CommunicationController.new(:random)
            message = {:command => :ok_to_run_project, 
                        :new_connection => temp_communicator.full_address,
                        :destination => remote_connection}
            @communicator.send_command(message)
            
            # Confirm that the client is using the new connection
            temp_communicator.wait_for_command(:confirm_new_connection) do |message|
            end
            
            # Get the Project
            branch = Models::Branch.from_number(branch_number)
            project = Models::Project.from_number(branch, project_number)
            
            # Create the Models
            new_models = nil
            begin
                new_models = Models::Data::XmlModelCreator::models_from_documents(project.document_models)
            rescue Exception => e
                raise "Could not load the document's models because: " + e.message
            end
            
            # Make the Models available to proxy through the connection
            models_connections =
            new_models.collect do |name, model|
                Helpers::Proxy.make_object_proxyable(:object => model, :name => :random)
            end
            
            # Create the Controller
            new_controller = nil
            begin
                project.document_controllers.each { |document| Kernel.eval(document.data) }
                new_controller = Kernel.eval(project.main_controller_class_name).new(new_models)
            rescue Exception => e
                raise "Could not load the document's controller because: " + e.message
            end
            
            # Make the Controller available to proxy through the connection
            controller_connection = Helpers::Proxy.make_object_proxyable(:object => new_controller, :name => :random)
            # Send the client a connection for talking to the Model and Controller
            message = {:command => :got_model_and_controller_connections,
                        :model_connections => models_connections,
                        :main_controller_connection => controller_connection,
                        :document_states => project.document_states,
                        :document_views => project.document_views,
                        :main_view_name => project.main_view_name,
                        :destination => remote_connection}
            temp_communicator.send_command(message)
            
            # Remove the temporary connection
            temp_communicator.close
        end
    end
end; end


