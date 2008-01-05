
require $IntuitiveFramework_Servers

module ID; module Servers
  class TestCommunicationServer < Test::Unit::TestCase
      def setup
          # Start the communication server
          @communication_server = Servers::CommunicationServer.new("127.0.0.1", 5555, true, :throw)
      end
            
      def teardown
          @communication_server.close if @communication_server
          ID::TestHelper.cleanup()      
      end

      def test_forwards_system_message
          # Create a unix socket that will accept the message
          message = nil
          t = Thread.new do
              dest_socket = Helpers::EasySocket.new(:system)
                  
              name = {:name => Servers::CommunicationServer.file_path + "destination:net"}
              dest_socket.read_messages(name) do |message_as_yaml|
                  message = YAML.load(message_as_yaml)
                  dest_socket.close
              end
          end
          
          # Send a message to the system communicator that will forward it to the destination
          
      end   
    end
end; end

