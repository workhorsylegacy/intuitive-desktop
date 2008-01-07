
require $IntuitiveFramework_Controllers

module ID; module Controllers
	    class TestCommunicationController < Test::Unit::TestCase
	       def setup
            ID::TestHelper.cleanup()
            @communication_server = Servers::CommunicationServer.new("127.0.0.1", 5555, true, :throw)
	           @communicator_one = Controllers::CommunicationController.new("one:system")
             @communicator_two = Controllers::CommunicationController.new("two:system")
	       end
	       
	       def teardown
            @communicator_one.close
            @communicator_two.close
            @communication_server.close
             ID::TestHelper.cleanup()
	       end
	       
	       def test_basic
	           assert @communicator_one.is_open
             assert_equal "one:system", @communicator_one.name
             assert_equal(Servers::CommunicationServer.file_path + "one:system", @communicator_one.full_name)
	       end
	     
            def test_wait_for_any_command
                command = nil
                t = Thread.new do
                    @communicator_one.wait_for_any_command do |message|
                        command = message[:command]
                    end
                end
                
                @communicator_two.send_command(@communicator_one.name, :command => :yo)
                t.join
                
                Thread.new do
                    sleep 3
                    raise "Timed out while waiting for the message"
                end
                
                # Make sure the communicator got the message
                assert_equal(:yo, command)
            end
            
            def test_wait_for_command
                command = nil
                t = Thread.new do
                    @communicator_one.wait_for_command(:yo) do |message|
                        command = message[:command]
                    end
                end
                
                @communicator_two.send_command(@communicator_one.name, :command => :yo)
                t.join
                
                # Make sure the communicator got the message
                assert_equal(:yo, command)
            end
	    end
end; end

