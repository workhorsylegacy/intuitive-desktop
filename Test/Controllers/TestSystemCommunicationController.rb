
require $IntuitiveFramework_Controllers

module Controllers
      class TestSystemCommunicationController < Test::Unit::TestCase
         def setup
             @service_name = "testo"
             @communicator_one = Controllers::SystemCommunicationController.new(@service_name)
             @communicator_two = Controllers::SystemCommunicationController.new()
         end
         
         def teardown
             @communicator_one.close if @communicator_one
             @communicator_two.close if @communicator_two
         end
         
         def test_name_lookup
            assert_equal(false, Controllers::SystemCommunicationController.is_name_used?("poop"))
            assert_equal(false, Controllers::SystemCommunicationController.is_name_used?("poop"))
         end
         
         def test_is_open
             assert(@communicator_one.is_incoming_open)
             assert(@communicator_one.is_open)
             assert_equal(@service_name, @communicator_one.name)
             
             assert(@communicator_two.is_incoming_open)
             assert(@communicator_two.is_open)
             assert_not_equal(nil, @communicator_two.name)
         end
         
         def test_communicators
             assert(@communicator_one)
             assert(@communicator_two)
             
             assert_not_equal(@communicator_one.name, @communicator_two.name)
         end
         
            def test_received_messages
                @communicator_one.send(@communicator_two.name, { :command => :yo, :body => "what up?" }) 
                @communicator_two.send(@communicator_one.name, { :command => :fu, :body => "your stank up fu" })
              
                # Make sure the communicators got the messages
                sleep(0.5)
                in_commands = @communicator_one.instance_variable_get("@in_commands")
                assert_equal(:fu, in_commands.first[:command])
                in_commands = @communicator_two.instance_variable_get("@in_commands")
                assert_equal(:yo, in_commands.first[:command])
            end
       
            def test_wait_for_any_command
                @communicator_one.send(@communicator_two.name, { :command => :yo }) 
                @communicator_two.send(@communicator_one.name, { :command => :fu })
                sleep(0.5)
                
                # Make sure the communicator is saving the messages
                in_commands = @communicator_one.instance_variable_get("@in_commands")
                assert_equal(1, in_commands.length)
                in_commands = @communicator_two.instance_variable_get("@in_commands")
                assert_equal(1, in_commands.length)
                
                result = {}
                @communicator_one.wait_for_any_command { |message| result[:one] = message[:command] }
                @communicator_two.wait_for_any_command { |message| result[:two] = message[:command] }             
              
                # Make sure the communicator is not storing any messages
                in_commands = @communicator_one.instance_variable_get("@in_commands")
                assert_equal(0, in_commands.length)
                in_commands = @communicator_two.instance_variable_get("@in_commands")
                assert_equal(0, in_commands.length)
              
                # Make sure the communicator got the messages
                assert_equal({:one => :fu, :two => :yo}, result)
            end
            
            def test_wait_for_command
                # Send some messages
                @communicator_one.send(@communicator_two.name, { :command => :yo, :body => "what up?" }) 
                @communicator_two.send(@communicator_one.name, { :command => :fu, :body => "your stank up fu" })
              
                # Make sure the communicator got the messages
                sleep(0.5)
                in_commands = @communicator_one.instance_variable_get("@in_commands")
                assert_equal(:fu, in_commands.first[:command])
                in_commands = @communicator_two.instance_variable_get("@in_commands")
                assert_equal(:yo, in_commands.first[:command])
              
                # Wait for the commands
                message_one = @communicator_one.wait_for_command(:fu)
                message_two = @communicator_two.wait_for_command(:yo)
              
                # Make sure the communicator got the messages
                sleep(0.5)
                assert_equal(:fu, message_one[:command])
                assert_equal(:yo, message_two[:command])
                
                # Make sure the messages are no longer on the communicator
                in_commands = @communicator_one.instance_variable_get("@in_commands")
                assert_equal(0, in_commands.length)
                in_commands = @communicator_two.instance_variable_get("@in_commands")
                assert_equal(0, in_commands.length)
            end            
      end
end

