
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

      def test_basic
          socket = Helpers::EasySocket.new(:name => "one")
           
          assert socket
          assert_equal :system, socket.mode
          assert_equal "one", socket.name
          assert_equal nil, socket.ip_address
          assert_equal nil, socket.port
          assert_equal({:name => "one"}, socket.full_address)
      end

      def test_system
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
          
          # Send a message to the destination socket
          out_message = {:command => :blah, 
                          :destination => {:name => "destination"}}
          source_socket = Helpers::EasySocket.new(:name => :source)
          source_socket.write_message(out_message)
          
          # Make sure we got the message
          t.join
          assert_equal(:blah, message[:command])
      end
    
      def test_net
          # Create a system socket that will accept the message
          message = nil
          t = Thread.new do
              dest_socket = Helpers::EasySocket.new(:ip_address => "127.0.0.1", :port => "5000", :name => "destination")
                  
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
          
          # Send a message to the destination socket
          out_message = {:command => :blah,
                          :destination => {:ip_address => "127.0.0.1", :port => "5000", :name => "destination"}}
          source_socket = Helpers::EasySocket.new(:name => "source")
          source_socket.write_message(out_message)
          
          # Make sure we got the message
          t.join
          assert_equal(:blah, message[:command])
      end
      
      def test_random_name
            # Create an easy socket with a random name
            socket = Helpers::EasySocket.new(:name => :random)
            
            # Make sure it has a name
            assert_not_equal "random",socket.name.to_s
            assert socket.name.length > 0
      end
      
      def test_fails_on_missing_destination
          # Send a message to a non existant net socket
          source_socket = Helpers::EasySocket.new(:ip_address => "127.0.0.1", :port => "5005", :name => "d")
          out_message = {:command => :blah}
          assert_raise(RuntimeError) do
              source_socket.write_message(out_message)
          end
      end
   end
end; end

