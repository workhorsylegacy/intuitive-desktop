
require $IntuitiveFramework_Servers
require $IntuitiveFramework_Models

module Servers
	class DocumentServer
        attr_reader :local_connection

        def initialize(logger_output=$stdout)
            # Make the data system if it does not exist
            Dir.mkdir($DataSystem) unless File.directory?($DataSystem)
            
            # a hash to store known identities
            @identities = {}.extend(MonitorMixin)
            
            @communicator = Servers::CommunicationServer.get_communicator()
            @local_connection = @communicator.create_network_connection
            
            @logger = Helpers::Logger.new(logger_output)
            
            # Respond to each request
            @thread = Thread.new {
                loop do
                    @communicator.wait_for_any_message(@local_connection) { |message|
                        case message[:command]
                            # Find and return any matching projects
                            when :find_projects
                                begin
                                    find_projects(message)
                                rescue Exception => e
                                    @logger.log :info, "Threw durring :find_documents: ", e
                                end
                            when :run_project
                                begin
                                    run_project(message)
                                rescue Exception => e
                                    # FIXME: Why is the logger not working here?
                                    puts e.message
                                    puts e.backtrace
                                    exit
                                    #@logger.log :info, "Threw durring :run_document: ", e
                                end
                            else
                                @logger.log :info, "Document Server does not know the command '#{message[:command]}'."
                        end
                    }
                end
            }
        end
        
        def is_open
            @communicator.is_open
        end
        
        def close
            @communicator.destroy_network_connection(@local_connection)
            #@communicator.close if @communicator
            @thread.exit
            @logger.close
        end
        
        private
        def find_projects(message)
            # Get the identity information
            remote_connection = message[:source_connection]

            # Find any projects with matching criteria
            projects = Controllers::DataController.find_projects(message[:criteria])
            
            message = {:command => :found_projects, 
                        :projects => projects}
            @communicator.send_message(@local_connection, remote_connection, message)        
        end
        
        def run_project(message)
            # Get the information
            remote_connection = message[:source_connection]
            project_number = message[:project_number]
            branch_number = message[:branch_number]

            # Create another connection just for this conversation and tell the remote machine to use it
            temp_connection = @communicator.create_connection
            message = {:command => :ok_to_run_project, :new_connection => temp_connection}
            @communicator.send_message(temp_connection, remote_connection, message)
            
            # Confirm that the client is using the new connection
            @communicator.wait_for_message(temp_connection, :confirm_new_connection)
            
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
                Helpers::Proxy.make_object_proxyable(model, @communicator)
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
            controller_connection = Helpers::Proxy.make_object_proxyable(new_controller, @communicator)
            # Send the client a connection for talking to the Model and Controller
            message = {:command => :got_model_and_controller_connections,
                        :model_connections => models_connections,
                        :main_controller_connection => controller_connection,
                        :document_states => project.document_states,
                        :document_views => project.document_views,
                        :main_view_name => project.main_view_name}
            @communicator.send_message(temp_connection, remote_connection, message)
            
            # Remove the temporary connection
            @communicator.destroy_connection(temp_connection)
        end     
	end
end

