
require $IntuitiveFramework_Views

module Views
    class TestView < Test::Unit::TestCase
            def test_load_from_string
                xml = "<View></View>"
                view = View::from_string(Program.new, xml)
        	       
                assert_not_nil(view)
            end
        end    	
end