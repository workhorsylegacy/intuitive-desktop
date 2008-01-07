
require $IntuitiveFramework_Servers

module ID; module Servers
  class TestCommunicationServer < Test::Unit::TestCase
      def setup
          ID::TestHelper.cleanup()
          # Start the communication server
          @communication_server = Servers::CommunicationServer.new("127.0.0.1", 5555, true, :throw)
      end
            
      def teardown
          @communication_server.close if @communication_server
          ID::TestHelper.cleanup()
      end

      def test_forwards_system_message
          # Create a system socket that will accept the message
          socket_name = {:name => Servers::CommunicationServer.file_path + "destination:system"}
          message = nil
          t = Thread.new do
              dest_socket = Helpers::EasySocket.new(:system)
                  
              dest_socket.read_messages(socket_name) do |message_as_yaml|
                  message = YAML.load(message_as_yaml)
                  dest_socket.close
              end
          end
          
          # Create a timeout thread, just incase it does not get the message
          death_thread = Thread.new do
              sleep 3
              raise "Timed out before the message was received."
          end
          
          # Send a message to the communication server that will forward it to the destination
          source_socket = Helpers::EasySocket.new(:system)
          out_message = {:command => :blah, 
                         :destination => Servers::CommunicationServer.file_path + "destination:system"}
          source_socket.write_message(out_message, :name => Servers::CommunicationServer.full_name)
          t.join
          
          # Make sure all the message has the same keys
          assert_equal(out_message[:command], message[:command])
          
          # Make sure the message has the new keys that were added by the communication server
          assert_equal("local", message[:source])
      end
      
      def test_forwards_net_messages
          warn "implement me"
      end
      
      def test_cant_send_from_net_to_system
          warn "implement me"
      end
      
      def test_cant_send_from_system_to_net
          warn "implement me"
      end
    end
end; end

