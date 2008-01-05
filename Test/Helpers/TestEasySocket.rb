
require $IntuitiveFramework_Helpers

module ID; module Helpers
  class TestEasySocket < Test::Unit::TestCase
      def setup
          # Delete any temp communication
          ID::TestHelper.cleanup()
      end
            
      def teardown
          # Delete any temp communication
          ID::TestHelper.cleanup()
      end

      def test_system
          # Create a system socket that will accept the message
          socket_args = {:name => $TempCommunicationDirectory + "destination"}
          message = nil
          t = Thread.new do
              dest_socket = Helpers::EasySocket.new(:system)
                  
              dest_socket.read_messages(socket_args) do |message_as_yaml|
                  message = YAML.load(message_as_yaml)
                  dest_socket.close
              end
          end
          
          # Create a timeout thread, just incase it does not get the message
          death_thread = Thread.new do
              sleep 3
              raise "Timed out before the message was received."
          end
          
          # Send a message to the destination socket
          source_socket = Helpers::EasySocket.new(:system)
          out_message = {:command => :blah}
          source_socket.write_message(out_message, socket_args)
          
          # Make sure we got the message
          t.join
          assert_equal(:blah, message[:command])
      end
    
      def test_net
          # Create a system socket that will accept the message
          socket_args = {:ip_address => "127.0.0.1",
                         :port => "5000"}
          message = nil
          t = Thread.new do
              dest_socket = Helpers::EasySocket.new(:net)
                  
              dest_socket.read_messages(socket_args) do |message_as_yaml|
                  message = YAML.load(message_as_yaml)
                  dest_socket.close
              end
          end
          
          # Create a timeout thread, just incase it does not get the message
          death_thread = Thread.new do
              sleep 3
              raise "Timed out before the message was received."
          end
          
          # Send a message to the destination socket
          source_socket = Helpers::EasySocket.new(:net)
          out_message = {:command => :blah}
          source_socket.write_message(out_message, socket_args)
          
          # Make sure we got the message
          t.join
          assert_equal(:blah, message[:command])
      end
   end
end; end

