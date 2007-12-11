
require $IntuitiveFramework_Views_Base
require $IntuitiveFramework_Models

module ID; module Views; module Base
        class TestMixinBindsToModel < Test::Unit::TestCase
          def teardown
              ID::TestHelper.cleanup()           
          end
          
            def test_bind_to_model
                # Create a button connected to a model
                xml = 	
<<XML
                <Button name="aligator_button">
                    <Binding name="get_name_age"
                        model="Alligators"
                        view_properties="text"
                        model_properties="name, age"
                        on_model_change="save_changes_to_view"
                        on_view_change="do_nothing" />
              </Button>
XML
                button = Views::Data::Button.from_string(nil, xml)
                
                # Create a test model
                xml = 	
<<XML
                <Models>
            		<Table name="Alligators">
            			<Column name="name" type="string" allows_null="false" />
            			<Column name="age" type="integer" allows_null="false" />
            			<Value name="fickle" age="56" />
            		</Table>
                </Models>
XML
                models = {}
                models = Models::Data::XmlModelCreator::models_from_xml_string(xml)
                alligators_class = models['Alligators']
                
                # Bind the button to the model
                button.bind_to_models(models, {})
                
                # Make sure the button is bound to the correct model
                binding = button.binding_for_property(:text)
                assert_equal(alligators_class, binding.model)
                assert_equal([:name, :age], binding.model_properties)
                assert_equal([:text], binding.view_properties)
                
                # Make sure the button is bound to the correct attribute
                assert_equal("fickle, 56", button.text)
            end
        end
end; end; end

