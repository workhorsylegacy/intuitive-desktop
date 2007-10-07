

module Servers
    class CommunicationServer
        attr_reader :on_error
        
        def self.start(on_error = :log_to_file)
            # Make sure the on_error is valid
            valid_on_error = [:log_to_file, :log_to_std_error, :throw]
            message = "The #{self.class.name} can only use #{valid_on_error.join(', ')} for on_error in its start method."
            raise message unless valid_on_error.include? on_error
            @on_error = on_error
            
            # Create the Dbus service
            bus = DBus::SessionBus.instance
            service = bus.request_service("org.intuitivedesktop.service")
            communication_server = CommunicationServerDBus.new("/org/intuitivedesktop/CommunicationServer")
            service.export(communication_server)
            
            # Start the Dbus service main loop in a thread
            puts "Running Intuitive Desktop Communication Server"
            @main_loop = Thread.new(bus) do |bus|
                @main = DBus::Main.new
                @main << bus
                @main.run
            end
            @main_loop.abort_on_exception = true
        end
        
        def self.stop
            @main_loop.exit if @main_loop
            @main = @main_loop = nil
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
    end
    
    private
    
    # The class that holds all the methods to be accessed by the dbus object
    class CommunicationServerDBus < DBus::Object
        dbus_interface "org.intuitivedesktop.CommunicationServerInterface" do
            dbus_method "is_running", "out message:b" do
                [true]
            end
            dbus_method("advertise_project_online", "in name:s, in description:s, in identity_public_key:s, in revision_number:i, out retval:b") do |name, description, identity_public_key, revision_number|
                # FIXME: Push the project info and our ip address onto the http://service.intuitive-desktop.org web serice
                [false]
            end
        end
    end
    
    # A class that wraps a CommunicationServerDBus
    class CommunicationServerWrapper
        def initialize(communicator)
            @real_communication_server = communicator
        end
        
        def is_running
            @real_communication_server.is_running
        end
        
        def advertise_project_online(project)
            @real_communication_server.advertise_project_online(project.name, project.description, project.parent_branch.user_id, project.parent_branch.head_revision_number)
        end
    end
end