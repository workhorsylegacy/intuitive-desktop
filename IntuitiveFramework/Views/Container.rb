
#path = File.dirname(File.expand_path(__FILE__))
#require "#{path}/Namespace"

module Views
    class Container < Views::Base::ContainerParentAndChild
        attr_reader :name
        
    	def initialize(name, pack_style)
            super(pack_style)
            
            @name = name
    	end
    	
    	def draw(window)
    	   @children.each { |child|
    	       child.draw(window)
    	   }
    	end  
    
        def self.from_string(parent, xml)
            xml_document = REXML::Document.new(xml)
            new_container = nil
        		
            xml_document.elements.each { |element|
                case(element.name)
                    when "Container": new_container = Container::from_xml(parent, element)
                    else raise "A Container element was not found in the xml file."
                end
            }  
        
            new_container
        end    
    
    	def self.from_xml(parent, element)
            # Create a container with the attributes
    		new_container = Container.new(
    		                              element.attributes['name'],
    		                              element.attributes['pack_style'])
            
            # Add child elements
    		element.elements.each { |e|
    		    child =
    			case(e.name)
                    when "Button": Views::Data::Button.from_xml(new_container, e)
                    when "Drawing": Views::Data::Drawing.from_xml(new_container, e)
                    when "Text": Views::Data::Text.from_xml(new_container, e)
    				when "List": Views::Data::List.from_xml(new_container, e)
    				when "Circle": Views::Shapes::Circle.from_xml(e)
    				when "Spinner": Views::Data::Spinner.from_xml(new_container, e)
    				when "Grid": Views::Data::Grid.from_xml(e)
    				when "Container": Views::Container.from_xml(new_container, e)
    				else raise "The Container does not know how to create a child of type '#{e.name}' from XML."
    			end
    			
    			child.connect_to_container(new_container) if child
    		}
    
    		new_container
    	end
    end
end
