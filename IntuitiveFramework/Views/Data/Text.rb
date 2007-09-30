
module Views
    module Data
        class Text < Views::Base::ContainerChild
            attr_reader :name, :default
            attr_accessor :spellcheck_style, :font_name, :font_color, :font_size, :on_text_changed_event
            
            def initialize(name, default='')
                super()
                @name = name
                @default = default
                
                @text=""
                
                @image = RSVG::Handle.new_from_file("#{$IntuitiveFramework}/Theme/Text.svg")
            end

            def image
                @image
            end

        	def draw(window)
                self.draw_image(window)                
                self.draw_text(window)
                self.draw_focus_highlight(window)
        	end
        	
        	def text_or_default
        	   curr_text = self.text
        	   if curr_text == ""
        	       return @default
        	   else
        	       return curr_text
        	   end
        	end
            
            def on_key_press_trigger(key_board_group, modify_keys, key_value)
                case key_value
                    when :backspace: self.text = self.text[0..-2] if self.text.length > 0
                    when :space: self.text += " "
                    else self.text += key_value
                end
                
                fire_events :on_key_press_event
            end
            
        	def self.from_xml(parent_container, element)
        		new_text = Text.new(element.attributes['name'],
        								element.attributes['default'])
        								
                new_text.spellcheck_style = (element.attributes['spellcheck_style'] || :standard).to_sym
                new_text.font_name = (element.attributes['font_name'] || 'Arial').to_s
                new_text.font_size = (element.attributes['font_size'] || 12).to_i
                new_text.font_color = Helpers::Color.hex_to_rgb(
                                                    element.attributes['font_color'] ||
                                                    '0x000000FF')
        
                # Add child elements
                element.elements.each do |e|
                    case e.name
                        when "Event": new_text.add_event(Helpers::Event.from_xml(new_text, e))
                        when "Binding": Helpers::Binding.from_xml(new_text, e)
                        else raise "The Text does not know how to create a child of type '#{e.name}' from XML."
                    end
                end 

                new_text.connect_to_container(parent_container)

        		new_text
        	end
        end
    end
end