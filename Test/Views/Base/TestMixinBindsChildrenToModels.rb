
require $IntuitiveFramework_Views_Base
require $IntuitiveFramework_Models

module ID; module Views; module Base
        class TestMixinBindsChildrenToModels < Test::Unit::TestCase
            class TestController < Controllers::DocumentController
                attr_reader :event_triggered
                
                def initialize(models)
                    super(models)
                    @event_triggered = false
                end
                
                def trigger_event
                    @event_triggered = true
                end
            end
            
          def teardown
              ID::TestHelper.cleanup()            
          end
            
            def test_bind_models
                # Create a document that has a button connected to a model
                xml = 	
<<XML
                <Container pack_style="horizontal">
                    <Button name="circle_radius_range">
                        <Binding name="get_size"
                            model="Squares"
                            view_properties="text"
                            model_properties="size"
                            on_model_change="save_changes_to_view"
                            on_view_change="do_nothing" />
                    </Button>
                </Container>
XML
                container = Views::Container.from_string(nil, xml)
                button = container.children.first
                
                # Create a test model
                xml = 	
<<XML
                      <Models>
                        <Table name="Squares">
                            <Column name="size" type="String" allows_null="false" />
                            <Value size="big" />
                    	</Table>
                      </Models>
XML
                state = {}
                models = Models::Data::XmlModelCreator::models_from_xml_string(xml)
                square_class = models['Squares']
                
                # Bind the children to the model
                container.bind_to_models(models, state)
                
                # Make sure the button is bound to the correct model
                binding = button.binding_for_property(:text)
                assert_same(square_class, binding.model)
                assert_equal([:size], binding.model_properties)
                assert_equal([:text], binding.view_properties)                
                
                # Make sure the button is bound to the correct attribute
                assert_equal("big", button.text)
            end
            
            def test_bind_events
                # Create a document that has a button connected to an event
                xml =
<<XML
                    <View name="window" title="" pack_style="vertical">
                        <Container name="container" pack_style="horizontal">
                            <Button name="circle_radius_range" >
                                <Event name="on_mouse_up_event"
                                        method="trigger_event" />
                            </Button>
                        </Container>
                    </View>
XML
                program = Program.new
                program.views = { 'window' => Views::View.from_string(program, xml) }
                program.models = {}
                program.states = {}
                program.views.each do |name, view|
                    program.main_view = view if name == 'window'
                end
                
                button = View::control_from_element_name(program.main_view, 'circle_radius_range')
                
                # Create a test controller and make sure its event has not been triggered
                program.main_controller = TestController.new(program.models)
                assert_equal(false, program.main_controller.event_triggered)
                
                # Bind the views to the controller's events
                program.setup_bindings
                
                # Make sure the button's event is the name of the controller's event
                event = button.event_map[:on_mouse_up_event].first
                assert_equal("on_mouse_up_event", event.name)
                assert_equal("trigger_event", event.method)
                assert_equal(nil, event.argument)
                assert_equal(nil, event.result)
                assert_equal(program.main_controller, event.method_controller)
                
                # Call the event and make sure it was triggered
                button.on_mouse_up_trigger(0, 0, nil)
                assert_equal(true, program.main_controller.event_triggered)        
            end
        end
end; end; end
