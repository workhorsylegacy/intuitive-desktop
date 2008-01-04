

module ID; module Servers
    class CommunicationServer
        attr_reader :generic_incoming_connection
        
        def self.force_kill_other_instances
            return unless Controllers::SystemCommunicationController.is_name_used?("CommunicationServer")
            
            unix_socket_file = Controllers::SystemCommunicationController.get_socket_file_name("CommunicationServer")
            File.delete(unix_socket_file) if File.exist?(unix_socket_file)
        end
        
        def initialize(ip_address, in_port, use_local_web_service, on_error)
            # Make sure the on_error is valid
            on_error_options = [:log_to_file, :log_to_std_error, :throw]
            message = "The Communication Server can only use #{on_error_options.join(', ')} for on_error."
            raise message unless on_error_options.include? on_error.to_sym
            @on_error = on_error

            # Create the net communicator
            @net_communicator = Controllers::CommunicationController.new(ip_address, in_port)

            # Create a generic connection for incoming messages from remote systems
            @generic_incoming_connection = self.create_net_connection

            start_generic_incoming_thread

            # Make the server available over the system communicator
            Helpers::SystemProxy.make_object_proxyable(self, "CommunicationServer")
        end
        
        def is_running?
            true
        end
        
        def close
            @generic_incoming_thread.kill if @generic_incoming_thread
            @net_communicator.close if @net_communicator
        end
            
        def ip_address
            @net_communicator.ip_address
        end
            
        def in_port
            @net_communicator.in_port
        end
            
        def on_error
            @on_error.to_s
        end
            
        def create_net_connection
            @net_communicator.create_connection
        end
            
        def destroy_net_connection(connection)
            @net_communicator.destroy_connection(connection)
        end
            
        def send_net_message(source_connection, dest_connection, message)
            @net_communicator.send_command(source_connection, dest_connection, message)
        end
        
        def wait_for_message(connection, command)
            # Make sure no block was given
            raise "This method does not except a block." if block_given?
          
            @net_communicator.wait_for_command(connection, command)
        end
        
        def wait_for_any_message(connection)
            # Make sure no block was given
            raise "This method does not except a block." if block_given?
          
            @net_communicator.wait_for_any_command(connection)
        end
        
        private
        
        def start_generic_incoming_thread
            @generic_incoming_thread = 
            Thread.new(@generic_incoming_connection) do |conn|
                loop do
                    message = self.wait_for_any_message(conn)
                    
                    # FIXME: The find_project should be called from the same place as the run_project
                    case message[:command]
                        when :run_project
                            run_project(message)
                        else
                          raise "The command #{message[:command]} was not expected."
                    end
                end
            end
        end
        
        # FIXME: This should not be in the communication server
        def run_project(message)
            # Get the information
            remote_connection = message[:source_connection]
            project_number = message[:project_number]
            branch_number = message[:branch_number]

            # Create another connection just for this conversation and tell the remote machine to use it
            temp_connection = self.create_net_connection
            message = {:command => :ok_to_run_project, :new_connection => temp_connection}
            self.send_net_message(temp_connection, remote_connection, message)
            
            # Confirm that the client is using the new connection
            self.wait_for_message(temp_connection, :confirm_new_connection)
            
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
                Helpers::Proxy.make_object_proxyable(model)
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
            controller_connection = Helpers::Proxy.make_object_proxyable(new_controller)
            # Send the client a connection for talking to the Model and Controller
            message = {:command => :got_model_and_controller_connections,
                        :model_connections => models_connections,
                        :main_controller_connection => controller_connection,
                        :document_states => project.document_states,
                        :document_views => project.document_views,
                        :main_view_name => project.main_view_name}
            self.send_net_message(temp_connection, remote_connection, message)
            
            # Remove the temporary connection
            self.destroy_net_connection(temp_connection)
        end 
    end
end; end

