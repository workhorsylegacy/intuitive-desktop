
require $IntuitiveFramework_Servers

module Servers
  class TestCommunicationServer < Test::Unit::TestCase
      def setup
          Servers::CommunicationServer.force_kill_other_instances()
          
          # Start the communication server
          @communication_server = Servers::CommunicationServer.new("127.0.0.1", 5555, 6666, true, :throw)
          
          # Create a net communicator that the server can talk to
          @other_net_communicator = Controllers::CommunicationController.new("127.0.0.1", 5000, 6000)
          @other_connection = @other_net_communicator.create_connection
      end
            
      def teardown
          @communication_server.close if @communication_server
          @other_net_communicator.close if @other_net_communicator
      end
            
      def test_is_running?
          assert(@communication_server.is_running?)
      end

      def test_send_net_message
          # Get a connection to the communication server
          server = Helpers::SystemProxy::get_proxy_to_object("CommunicationServer")
          assert_not_nil(server)
         
          # Make sure we can get a net connection
          connection = server.create_net_connection
          assert(connection.is_a?(Hash))
          
          # Make sure we can use the send_net_message
          message = {:command => :sup_other}
          server.send_net_message(connection, @other_connection, message)
          got_message = 
          @other_net_communicator.wait_for_command(@other_connection, :sup_other)
          assert_equal(message[:command], got_message[:command])
      end
      
      def test_wait_for_net_message
          # Get a connection to the communication server
          server = Helpers::SystemProxy::get_proxy_to_object("CommunicationServer")
          assert_not_nil(server)
         
          # Make sure we can get a net connection
          connection = server.create_net_connection
          assert(connection.is_a?(Hash))
          
          # Make sure we can use the wait_for_net_message
          message = {:command => :sup_server}
          @other_net_communicator.send(@other_connection, connection, message)
          got_message = 
          server.wait_for_net_message(connection, :sup_server)
          assert_equal(message[:command], got_message[:command])
      end
      
      def test_wait_for_any_net_message
          # Get a connection to the communication server
          server = Helpers::SystemProxy::get_proxy_to_object("CommunicationServer")
          assert_not_nil(server)
         
          # Make sure we can get a net connection
          connection = server.create_net_connection
          assert(connection.is_a?(Hash))
          
          # Make sure we can use the wait_for_any_net_message
          message = {:command => :sup_server}
          @other_net_communicator.send(@other_connection, connection, message)
          got_message = server.wait_for_any_net_message(connection)
          assert_equal(message[:command], got_message[:command])
      end      
    end
end

