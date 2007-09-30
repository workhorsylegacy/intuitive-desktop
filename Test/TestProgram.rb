

path = File.dirname(File.expand_path(__FILE__))
require "#{path}/../IntuitiveFramework/IntuitiveFramework.rb"


    class TestProgram < Test::Unit::TestCase
            def test_load_from_string
                view_xml =
<<VIEW_XML
                   <View>
                      <Container pack_style="vertical">
            			       <Button name="person" />
            		      </Container>                   
                   </View>
VIEW_XML
                models_xml =
<<MODEL_XML
                  <Models>
                      <Table name="Persons">
                          <Column name="name" type="string" allows_null="false" />
                      </Table>
                  </Models>
MODEL_XML
                # Create a program from the xml
                program = Program.new
                program.main_view = Views::View.from_string(program, view_xml)
                program.models = Models::Data::XmlModelCreator.models_from_xml_string(models_xml)
        	    
        	      # Make sure the program is valid
                assert_not_nil(program)
                assert_not_nil(program.main_view)
                assert_equal(1, program.models.length)
                
                # Make sure the button is valid
                assert_not_nil(program.main_view.children[0].children[0])
            end
        end
