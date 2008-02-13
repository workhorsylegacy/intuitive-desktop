
module ID; module Views; module Data
        class Spinner < Views::Base::ContainerParentAndChild
            attr_reader :name, :button_up, :button_down
            
            def initialize(name)
                super(:horizontal)
                @name = name
                @is_pressed = false
                
                # Add a textbox and two buttons
                @text_view = Views::Data::Text.new('text')
                @button_up = Views::Data::Button.new('button_up')
                @button_down = Views::Data::Button.new('button_down')
                @button_container = Views::Container.new('container', :vertical)
                
                @text_view.connect_to_container(self)
                @button_up.connect_to_container(@button_container)
                @button_down.connect_to_container(@button_container)
                @button_container.connect_to_container(self)
            end
            
            def min_width
                100
            end
            
            def min_height
                30
            end
    
        	def draw(window)
        	   # Draw the text and buttons
        	   @button_container.draw(window)
        	   @text_view.draw(window)
        	end
        	
        	def self.from_xml(parent_container, element)
        		new_spinner = Spinner.new(element.attributes['name'])
        										
                # Add child elements
                element.elements.each do |e|
                    case e.name
                        when "Event": new_spinner.add_event(Helpers::Event.from_xml(new_spinner, e))
                        when "Binding": Helpers::Binding.from_xml(new_spinner, e)
                        else raise "The Spinner does not know how to create a child of type '#{e.name}' from XML."
                    end
                end                
        
                new_spinner.connect_to_container(parent_container)
        		new_spinner
        	end        	
        end
end; end; end