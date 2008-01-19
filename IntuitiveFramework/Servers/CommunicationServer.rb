
require $IntuitiveFramework_Helpers

module ID; module Servers
    class CommunicationServer
        attr_reader :is_open, :ip_address, :port, :system_name, :on_error
        
        def initialize(on_error)
            # Make sure the on_error is valid
            on_error_options = [:log_to_file, :log_to_std_error, :throw]
            message = "The Communication Server can only use #{on_error_options.join(', ')} for on_error."
            raise message unless on_error_options.include? on_error.to_sym
            @on_error = on_error
            
            @is_open = false
            @ip_address = ID::Config.ip_address
            @port = ID::Config.port
            @system_name = "CommunicationServer"

            self.open
        end
        
        def open
            # Just return if it is already open
            return if @is_open
            
            @is_open = true
            start_threads
        end
        
        def close
            # Just return if it is already closed
            return unless @is_open
            
            @is_open = false
            stop_threads
        end
        
        def self.file_path
          ID::Config.comm_dir
        end
        
        def self.full_name
            file_path + @system_name
        end
      
      def self.is_name_used?(name)
          File.exist? file_path + name
      end
        
        private
        
        def stop_threads
            @system_socket.close
            @net_socket.close
            @system_thread.kill
            @net_thread.kill
        end
        
        def start_threads
            @system_socket = Helpers::EasySocket.new(:name => @system_name)
            @system_thread = Thread.new do
                @system_socket.read_messages do |message_as_yaml|
                    forward_message(message_as_yaml)
                end
            end
            
            @net_socket = Helpers::EasySocket.new(:ip_address => @ip_address, :port => @port)
            @net_thread = Thread.new do
                @net_socket.read_messages do |message_as_yaml|
                    forward_message(message_as_yaml)
                end
            end
        end 
       
        private
        
        def forward_message(message_as_yaml)
            message_as_ruby = YAML.load(message_as_yaml)
            
            # Make sure the message is valid
            raise "The message is not a Hash." unless message_as_ruby.class == Hash
            raise "The message is missing the source." unless message_as_ruby.has_key?(:source)
            raise "The message is missing the destination." unless message_as_ruby.has_key?(:destination)
            raise "The message is missing the real destination." unless message_as_ruby.has_key?(:real_destination)
            raise "The message is missing the command." unless message_as_ruby.has_key?(:command)
                  
            # Determine if we are sending to a local socket, or remote socket
            destination = message_as_ruby[:destination]
            is_remote = destination.has_key?(:ip_address) && destination.has_key?(:port)
                  
            # Make sure the destination exist if it is local
            unless is_remote
                dest_name = destination[:name]
                raise "No system destination named '#{dest_name}' to send to." unless self.class.is_name_used?(dest_name)
            end
             
            # Change the destination to be the real destination
            message_as_ruby[:destination] = message_as_ruby.delete(:real_destination)
             
            # Forward the message to the dest socket socket
            out_socket = Helpers::EasySocket.new(:name => :random)
            out_socket.write_message(message_as_ruby)
            out_socket.close()
        end
        
=begin
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
=end
    end
end; end

