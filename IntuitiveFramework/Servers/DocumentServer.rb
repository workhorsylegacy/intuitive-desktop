
=begin
require $IntuitiveFramework_Servers
require $IntuitiveFramework_Models

module ID; module Servers
    # FIXME: Rename to DataServer
	class DocumentServer
        attr_reader :generic_net_connection

        def initialize(logger_output=$stdout)
            # Make the data system if it does not exist
            Dir.mkdir($DataSystem) unless File.directory?($DataSystem)
            
            # a hash to store known identities
            @identities = {}.extend(MonitorMixin)
            
            # Create the net communicator
            @net_communicator = Controllers::CommunicationController.new(ip_address, in_port, out_port)
            @generic_net_connection = @net_communicator.create_connection
                    
            # Create the system communicator
            if Controllers::SystemCommunicationController.is_name_used?("DocumentServer")
                raise "The Document Server is already running."
            end
            
            # Make the server available over the system communicator
            Helpers::SystemProxy.make_object_proxyable(self, "DocumentServer")
            
            @logger = Helpers::Logger.new(logger_output)
            
            # Respond to each request
            @thread = Thread.new {
                loop do
                    @net_communicator.wait_for_any_command(@generic_net_connection) { |message|
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
            @net_communicator.is_open
        end
        
        def close
            #@net_communicator.destroy_network_connection(@generic_net_connection)
            @net_communicator.close if @net_communicator
            @system_communicator.close if @system_communicator
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
            @net_communicator.send_message(@generic_net_connection, remote_connection, message)        
        end
        
        def run_project(message)
            # Get the information
            remote_connection = message[:source_connection]
            project_number = message[:project_number]
            branch_number = message[:branch_number]

            # Create another connection just for this conversation and tell the remote machine to use it
            temp_connection = @net_communicator.create_connection
            message = {:command => :ok_to_run_project, :new_connection => temp_connection}
            @net_communicator.send(temp_connection, remote_connection, message)
            
            # Confirm that the client is using the new connection
            @net_communicator.wait_for_command(temp_connection, :confirm_new_connection)
            
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
                Helpers::Proxy.make_object_proxyable(model, @net_communicator)
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
            controller_connection = Helpers::Proxy.make_object_proxyable(new_controller, @net_communicator)
            # Send the client a connection for talking to the Model and Controller
            message = {:command => :got_model_and_controller_connections,
                        :model_connections => models_connections,
                        :main_controller_connection => controller_connection,
                        :document_states => project.document_states,
                        :document_views => project.document_views,
                        :main_view_name => project.main_view_name}
            @net_communicator.send(temp_connection, remote_connection, message)
            
            # Remove the temporary connection
            @net_communicator.destroy_connection(temp_connection)
        end     
	end
end; end


=end