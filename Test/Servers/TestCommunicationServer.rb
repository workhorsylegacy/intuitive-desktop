
require $IntuitiveFramework_Servers

module ID; module Servers
  class TestCommunicationServer < Test::Unit::TestCase
      def setup
          ID::TestHelper.cleanup()
          # Start the communication server
          @communication_server = Servers::CommunicationServer.new(:throw)
      end
            
      def teardown
          @communication_server.close if @communication_server
          ID::TestHelper.cleanup()
      end

      def test_forwards_system_message
          # Create a system socket that will accept the message
          message = nil
          t = Thread.new do
              dest_socket = Helpers::EasySocket.new(:name => "destination")
                  
              dest_socket.read_messages do |message_as_yaml|
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
          source_socket = Helpers::EasySocket.new(:name => "source")
          out_message = {:command => :blah, 
                         :destination => {:name => "CommunicationServer"},
                         :real_destination => {:name => "destination"}}
          source_socket.write_message(out_message)
          t.join
          
          # Make sure all the message has the same keys
          assert_equal(out_message[:command], message[:command])
          
          # Make sure the message has the new keys that were added by the communication server
          assert_equal("source", message[:source][:name])
      end
      
      def test_forwards_net_messages
          # Create a system socket that will accept the message
          message = nil
          t = Thread.new do
              dest_socket = Helpers::EasySocket.new(:ip_address => "127.0.0.1", :port => 4567)
                  
              dest_socket.read_messages do |message_as_yaml|
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
          source_socket = Helpers::EasySocket.new(:name => "source")
          out_message = {:command => :blah, 
                         :destination => {:name => "CommunicationServer"},
                         :real_destination => {:ip_address => "127.0.0.1", :port => 4567}}
          source_socket.write_message(out_message)
          t.join
          
          # Make sure all the message has the same keys
          assert_equal(out_message[:command], message[:command])
          
          # Make sure the message has the new keys that were added by the communication server
          assert_equal("source", message[:source][:name])
      end
    end
end; end

