

module ID; module Views; module Data
        class Button < Views::Base::ContainerChild
            attr_reader :name
            
            def initialize(name)
                super()
                @name = name
                
                @image_not_pressed = RSVG::Handle.new_from_file("#{$IntuitiveFramework}/Theme/Button.svg")
                @image_pressed = RSVG::Handle.new_from_file("#{$IntuitiveFramework}/Theme/Button_pressed.svg")
            end
    
            def image
                if @is_pressed
                    @image_pressed 
                else
                    @image_not_pressed
                end
            end
    
        	def draw(window)
                self.draw_image(window)                
                self.draw_text(window)
                self.draw_focus_highlight(window)
        	end
        	
            def self.from_string(parent, xml)
                xml_document = REXML::Document.new(xml)
                new_button = nil
            		
                xml_document.elements.each { |element|
                    case(element.name)
                        when "Button": new_button = Button::from_xml(parent, element)
                        else raise "A Button element was not found in the xml file."
                    end
                }  
            
                new_button
            end    
        	
        	def self.from_xml(parent_container, element)
        		new_button = Button.new(element.attributes['name'])

                # Add child elements
                element.elements.each do |e|
                    case e.name
                        when "Event": new_button.add_event(Helpers::Event.from_xml(new_button, e))
                        when "Binding": Helpers::Binding.from_xml(new_button, e)
                        else raise "The Button does not know how to create a child of type '#{e.name}' from XML."
                    end
                end                    
        
                new_button.connect_to_container(parent_container)
        		new_button
        	end        	
        end
end; end; end
