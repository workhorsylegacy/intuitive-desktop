
require $IntuitiveFramework_Controllers

module ID; module Controllers
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
             
             ID::TestHelper.cleanup()
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
	     
            def test_wait_for_any_command
                message = nil
                t = Thread.new do
                    message = @communicator.wait_for_any_command(@connection_one)[:command]
                end
            
                @communicator.send_command(@connection_two, @connection_one, { :command => :yo }) 
                t.join()
                
                # Make sure the communicator got the message
                assert_equal(:yo, message)
            end
            
            def test_wait_for_command
                message = nil
                t = Thread.new do
                    message = @communicator.wait_for_command(@connection_one, :yo)[:command]
                end
                
                @communicator.send_command(@connection_two, @connection_one, { :command => :yo, :body => "what up?" })
                t.join
                
                # Make sure the communicator got the message
                assert_equal(:yo, message)
            end
	    end
end; end

