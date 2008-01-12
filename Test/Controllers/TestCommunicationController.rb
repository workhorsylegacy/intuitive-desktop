
require $IntuitiveFramework_Controllers

module ID; module Controllers
	    class TestCommunicationController < Test::Unit::TestCase
	       def setup
            ID::TestHelper.cleanup()
            @communication_server = Servers::CommunicationServer.new("127.0.0.1", 5555, true, :throw)
	           @communicator_one = Controllers::CommunicationController.new(:name => :one, :type => :system)
             @communicator_two = Controllers::CommunicationController.new(:name => :two, :type => :system)
	       end
	       
	       def teardown
            @communicator_one.close
            @communicator_two.close
            @communication_server.close
             ID::TestHelper.cleanup()
	       end
	       
	       def test_basic
	           assert @communicator_one.is_open
             assert_equal "one:system", @communicator_one.name_type
             assert_equal(Servers::CommunicationServer.file_path + "one:system", @communicator_one.full_name)
	       end
	     
         def test_random_name
            # Get rid of the default communicator
            @communicator_one.close if @communicator_one
            
            # Create a communicator with a random name
            @communicator_one = Controllers::CommunicationController.new(:name => :random, :type => :system)
            
            # Make sure it has a name
            assert_not_nil @communicator_one
            assert_not_equal "*", @communicator_one.name.split(':').first
            assert @communicator_one.name.split(':').first.length > 0
         end
       
            def test_wait_for_any_command
                command = nil
                t = Thread.new do
                    @communicator_one.wait_for_any_command do |message|
                        command = message[:command]
                    end
                end
                
                @communicator_two.send_command(@communicator_one.name_type, :command => :yo)
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
                
                @communicator_two.send_command(@communicator_one.name_type, :command => :yo)
                t.join
                
                # Make sure the communicator got the message
                assert_equal(:yo, command)
            end
	    end
end; end

