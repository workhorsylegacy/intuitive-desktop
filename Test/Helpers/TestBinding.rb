
module Helpers
        class TestBinding < Test::Unit::TestCase
            def test_from_xml
                # Create a Binding from xml
                xml =
<<XML
                <Binding name="highlight_width"
                      on_model_change="save_changes_to_view"
                      on_view_change="save_changes_to_model"
                      model="SelectedWidth"
                      model_properties="width"
                      view_properties="highlight_width" />
XML

                line = Views::Data::Line.new('test_line')
                binding = Helpers::Binding.from_string(line, xml)
                
                # Make sure the binding is valid
                assert_same(line, binding.parent)
                assert_equal('highlight_width', binding.name)
                assert_equal(:save_changes_to_view, binding.on_model_change)
                assert_equal(:save_changes_to_model, binding.on_view_change)
                assert_equal('SelectedWidth', binding.model)
                assert_equal([:width], binding.model_properties)
                assert_equal([:highlight_width], binding.view_properties)
                
                # Make sure the binding is connected to the line
                assert_same(binding, line.property_to_binding_map[:highlight_width])
            end
        
            def test_model_binding
                # Create a model
                xml = 
<<XML
                  <Models>
                    <Table name="SelectedWidths">
                      <Column name="name" type="string" allows_null="false" />
                      <Column name="width" type="float" allows_null="false" />
                      <Value name="medium" width="5" />
                    </Table>
                  </Models>
XML
                models = Models::Data::XmlModelCreator::models_from_xml_string(xml)
                
                # Create a Binding
                xml =
<<XML
                <Binding name="highlight_width"
                      on_model_change="do_nothing"
                      on_view_change="do_nothing"
                      model="SelectedWidths"
                      model_properties="width"
                      view_properties="highlight_width" />
XML

                # Get the binding conected
                line = Views::Data::Line.new('test_line')
                binding = Helpers::Binding.from_string(line, xml)
                line.bind_to_models(models, nil)
                
                # Make sure the line, and model are connected to the binding
                assert_equal(binding, line.property_to_binding_map[:highlight_width])
                assert(SelectedWidths.bindings.include?(binding))
                
                # Make sure the default values are correct
                assert_equal(0, line.highlight_width)
                assert_equal(5, SelectedWidths.find(:first).width)       
                
                #
                # Make sure the on_view_change mode of save_changes_to_model works
                #
                binding.on_view_change = :save_changes_to_model
                assert_same(:save_changes_to_model, binding.on_view_change)
                
                # Change the view and make sure it updates the model
                line.highlight_width = 6
                assert_equal(6, line.highlight_width)
                assert_equal(6, SelectedWidths.find(:first).width)
                
                #
                # Make sure the on_view_change mode of do_nothing works
                #
                binding.on_view_change = :do_nothing
                assert_same(:do_nothing, binding.on_view_change)
                
                # Change the view and make sure it doesn't update the model
                line.highlight_width = 34.5
                assert_equal(34.5, line.highlight_width)
                assert_equal(6, SelectedWidths.find(:first).width)

                #
                # Make sure the on_model_change mode of save_changes_to_view works
                #
                binding.on_view_change = :do_nothing
                binding.on_model_change = :save_changes_to_view
                assert_same(:save_changes_to_view, binding.on_model_change)
                
                # Change the model and make sure it updates the view
                model = SelectedWidths.find(:first)
                model.width = 0.4
                model.update
                assert_equal(0.4, line.highlight_width)
                assert_equal(0.4, SelectedWidths.find(:first).width)

                #
                # Make sure the on_model_change mode of do_nothing works
                #
                binding.on_model_change = :do_nothing
                assert_same(:do_nothing, binding.on_model_change)
                
                # Change the model and make sure it doesn't update the view
                model = SelectedWidths.find(:first)
                model.width = 7
                model.update
                assert_equal(0.4, line.highlight_width)
                assert_equal(7,  SelectedWidths.find(:first).width)

                # Disconnect the line from the model and make sure it is disconnected
            end
            
            def test_bound_properties
                # Make sure that the properties with the correct number on each side match
                # Make sure that properties with the wrond number on a side fail
                # Make sure that an incorrect property fails
                # Make sure that a blank property fails
                raise "add these tests!"
            end
        end
end