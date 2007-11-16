
require $IntuitiveFramework_Helpers
require $IntuitiveFramework_Controllers

module Helpers
	class TestProxy < Test::Unit::TestCase
        def setup
            Servers::CommunicationServer.force_kill_other_instances()
          
            # Start the communication server
            @communication_server = Servers::CommunicationServer.new("127.0.0.1", 5555, true, :throw)    
        
            # Create an object that will be accessed by a proxy
            @object = Object.new
            def @object.name
                @name
            end
            def @object.name=(value)
                @name = value
            end
            @object.name = "my name is object"
            
            # Start proxying the object
            remote_connection = Helpers::Proxy.make_object_proxyable(@object)
            assert(remote_connection.is_a?(Hash))
            
            # Get a proxy to the real object
            @proxy = Helpers::Proxy.get_proxy_to_object(remote_connection)
            assert_not_nil(@proxy)
        end
        
        def teardown
            @communication_server.close if @communication_server
        end
        
        def test_proxy_object
            # Make sure the object is proxied
            assert_equal("my name is object", @object.name)
            assert_equal("my name is object", @proxy.name)
            
            @proxy.name = "proxy of doom"
            assert_equal("proxy of doom", @object.name)
            assert_equal("proxy of doom", @proxy.name)
        end
        
        def test_send
            def @object.add(a, b)
                a + b
            end
            
            # Make sure .send works
            assert_equal(11, @proxy.send(:add, 4, 7))
            assert_equal(11, @proxy.add(4, 7))
        end
        
        def test_exceptions
            # Make sure it forwards exceptions
            assert_raise(Helpers::ProxiedException) { @proxy.kaboom }
            
            # Make sure the exception did not break the real object
            assert_equal("my name is object", @object.name)
        end
        
        def test_object_methods
            # Add a common methods that is present in all Objects
            def @object.respond_to?(name)
                'only on the weekends'
            end
            
            # Make sure that method is forwarded too
            assert_equal('only on the weekends', @proxy.respond_to?(:something_fake))
        end
        
        def test_class
            assert_equal(Object, @object.class)
            
            # Make sure that .class does not work
            assert_raise(Helpers::ProxiedException) { @proxy.class }
        end
        
=begin FIXME: Add these tests to see what happens when the real object or proxy is GCed
              or the communicator or connections break or turn off
              or any of them time out.
=end

#        def test_proxy_disconnect
#            # Make sure the proxy is connected
#            assert_equal("my name is object", @proxy.name)
#            
#            # Destroy the proxy and run GC to remove it from memory
#            #undefine proxy
#            ObjectSpace.garbage_collect
#            sleep(2)
#            
#            # Make sure that the real object was undefined when the proxy was
#            assert_equal(false, defined? @object)
#        end
#        
#        # Test what happens to a proxy when the real object's channel dies
#        def test_connection_fail
#            # Make sure the proxy is connected
#            assert_equal("my name is object", @proxy.name)
#            
#            # Turn off the remote communicator
#            @remote_communicator.close
#            
#            # Make sure this throws a RuntimeError when it times out
#            assert_raise(RuntimeError) { @proxy.name }
#        end
#        
#        def test_timeout
#            @object = Object.new
#            def @object.sig
#                'me'
#            end
#            
#            # Start proxying the object
#            remote_connection = Helpers::Proxy.make_object_proxyable(@object, @remote_communicator, 60)
#            
#            # Get a proxy to the real object
#            @proxy = Helpers::Proxy.get_proxy_to_object(@local_communicator, remote_connection, 2)
#            
#            # Close the communicator on the real object and let the proxy time out
#            @remote_communicator.close
#            sleep 3
#            
#            # FIXME: Here see what happens to the proxies life ticker when the real object is disconnected
#            assert_equal('me', @proxy.sig)
#        end
#        
#        def test_more_of_them
#            raise "Test the proxies connection ending when it is GCed"
#            raise "Test the real object's connection timing out when the proxy is unplugged"
#            raise "Test what happens when the proxy does not handle an exception from the real object"
#            raise "Test what happens when the real object is disconnected"
#        end
    end
end

