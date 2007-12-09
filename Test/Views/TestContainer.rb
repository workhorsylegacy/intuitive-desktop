
require $IntuitiveFramework_Views

module ID; module Views
    class TestContainer < Test::Unit::TestCase
            def test_load_from_string
                xml = 
                "<Container pack_style=\"vertical\" > \
                    <Container pack_style=\"horizontal\" /> \
                </Container>"
                container = Container::from_string(nil, xml)
        	       
                assert_not_nil(container)
                assert_equal(:vertical, container.pack_style)
                assert_equal(1, container.children.length)
            end
        end    	
end; end
