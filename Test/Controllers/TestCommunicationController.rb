
require $IntuitiveFramework_Controllers

module ID; module Controllers
	    class TestCommunicationController < Test::Unit::TestCase
	       def setup
            ID::TestHelper.cleanup()
            @communication_server = Servers::CommunicationServer.new(:throw)
	           @communicator_one = Controllers::CommunicationController.new("one")
             @communicator_two = Controllers::CommunicationController.new("two")
	       end
	       
	       def teardown
            @communicator_one.close
            @communicator_two.close
            @communication_server.close
             ID::TestHelper.cleanup()
	       end
	       
	       def test_basic
	           assert @communicator_one.is_open
             assert_equal :system, @communicator_one.mode
             assert_equal "one", @communicator_one.name
             assert_equal nil, @communicator_one.ip_address
             assert_equal nil, @communicator_one.port
             assert_equal({:name => "one"}, @communicator_one.full_address)
	       end

         def test_net_messages_routed_correctly
            # Create an easy socket that will receive the message
            message = nil
            t = Thread.new do
                socket = Helpers::EasySocket.new(:name => "destination")
                
                socket.read_messages do |message_as_yaml|
                    message = YAML.load(message_as_yaml)
                    socket.close
                end
            end
            
            # Create a timeout thread, just incase it does not get the message
            death_thread = Thread.new do
                sleep 3
                raise "Timed out before the message was received."
            end
            
            # Send a message to the easy socket and make sure it gets there
            out_message = {:destination => {:name => "destination"},
                                            :command => "blah"}
            @communicator_one.send_command(out_message)
            t.join
            
            # Make sure the message is correct
            assert_equal out_message[:destination], message[:destination]
            assert_equal out_message[:command], message[:command]
            
            # Make sure the message has the routing info added to it
            assert message.has_key?(:routing)
            assert_equal({:name => "CommunicationServer"}, message[:routing])
            assert_equal({:name => "one"}, message[:source])
         end
       
            def test_wait_for_any_command
                command = nil
                t = Thread.new do
                    @communicator_one.wait_for_any_command do |message|
                        command = message[:command]
                    end
                end
                
                @communicator_two.send_command(:command => :yo, :destination => {:name => "one"})
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
                
                @communicator_two.send_command(:command => :yo, :destination => {:name => "one"})
                t.join
                
                # Make sure the communicator got the message
                assert_equal(:yo, command)
            end
	    end
end; end

