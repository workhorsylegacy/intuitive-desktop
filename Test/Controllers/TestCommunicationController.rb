
require $IntuitiveFramework_Controllers

module Controllers
	    class TestCommunicationController < Test::Unit::TestCase
	       def setup
	           @ip_address = "127.0.0.1"
	           @in_port = 7001
	           @communicator = Controllers::CommunicationController.new(@ip_address, @in_port)
	           
	           @connection_one = @communicator.create_connection
	           @connection_two = @communicator.create_connection
	       end
	       
	       def teardown
	           @communicator.close if @communicator
	       end
	       
	       def test_is_open
	           assert(@communicator.is_incoming_open)
	           assert(@communicator.is_open)
	       end
	       
	       def test_connections
	           assert(@connection_one)
	           assert(@connection_two)
	           
	           assert_not_equal(@connection_one[:id], @connection_two[:id])
	       end
	       
            def test_received_messages
                @communicator.send_command(@connection_two, @connection_one, { :command => :yo, :body => "what up?" }) 
                @communicator.send_command(@connection_one, @connection_two, { :command => :fu, :body => "your stank up fu" })
              
                # Make sure the communicator got the messages
                sleep(0.5)
                in_commands = @communicator.instance_variable_get("@in_commands")
                assert_equal(:yo, in_commands[@connection_one[:id]][0][:command])
                assert_equal(:fu, in_commands[@connection_two[:id]][0][:command])
            end
	     
            def test_wait_for_any_command
                @communicator.send_command(@connection_two, @connection_one, { :command => :yo }) 
                @communicator.send_command(@connection_one, @connection_two, { :command => :fu })
                sleep(0.5)
                
                # Make sure the communicator is saving the messages
                in_commands = @communicator.instance_variable_get("@in_commands")
                assert_equal(1, in_commands[@connection_one[:id]].length)
                assert_equal(1, in_commands[@connection_two[:id]].length)
                
                result = {}
                @communicator.wait_for_any_command(@connection_one) { |message| result[:one] = message[:command] }
                @communicator.wait_for_any_command(@connection_two) { |message| result[:two] = message[:command] }             
              
                # Make sure the communicator is not storing any messages
                in_commands = @communicator.instance_variable_get("@in_commands")
                assert_equal(0, in_commands[@connection_one[:id]].length)
                assert_equal(0, in_commands[@connection_two[:id]].length)
              
                # Make sure the communicator got the messages
                assert_equal({:one => :yo, :two => :fu}, result)
            end
            
            def test_wait_for_command
                # Send some messages
                @communicator.send_command(@connection_two, @connection_one, { :command => :yo, :body => "what up?" }) 
                @communicator.send_command(@connection_one, @connection_two, { :command => :fu, :body => "your stank up fu" })
              
                # Make sure the communicator got the messages
                sleep(0.5)
                in_commands = @communicator.instance_variable_get("@in_commands")
                assert_equal(:yo, in_commands[@connection_one[:id]][0][:command])
                assert_equal(:fu, in_commands[@connection_two[:id]][0][:command])
              
                # Wait for the commands
                message_one = @communicator.wait_for_command(@connection_one, :yo)
                message_two = @communicator.wait_for_command(@connection_two, :fu)
              
                # Make sure the communicator got the messages
                sleep(0.5)
                assert_equal(:yo, message_one[:command])
                assert_equal(:fu, message_two[:command])
                
                # Make sure the messages are no longer on the communicator
                in_commands = @communicator.instance_variable_get("@in_commands")
                assert_equal(0, in_commands[@connection_one[:id]].length)
                assert_equal(0, in_commands[@connection_two[:id]].length)
            end
	    end
end

