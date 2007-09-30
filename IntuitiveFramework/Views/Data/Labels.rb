
module Views
    module Data
        class Labels < Views::Base::ContainerChild
            attr_reader :parent, :name
            attr_accessor :spellcheck_style, :font_name, :font_color, :font_size, :items, :position_indicator
            
            def initialize(name)
                super()
                @name = name
                @items = []
            end

            def items
                # Update the property if it gets changes from the model
                if @property_to_binding_map && @property_to_binding_map.has_key?(:items)
                    binding = @property_to_binding_map[:items] || []
                    if binding.on_model_change == :save_changes_to_view
                        data = @property_to_binding_map[:items].get_model_data
                        if @old_model_items != data
                            @old_model_items = data
                            @items = data
                        end
                    end
                end
                
                # Return the property
                @items
            end
            
            def items=(value)
                raise "Can't set this yet!"
            end

          def draw(cr, window, zoom)
              self.items.each do |text, text_x, text_y|
                  width = 100
                  height = 50

                  # Draw the position_indicator
                  [
                      [[0, 0, 0, 1], 3],
                      [[1, 0, 0, 1], 2]
                  ].each do |color, size|
                      cr.set_source_rgba(*color)
                      case @position_indicator
                          when :dot:
                              cr.circle(text_x, text_y, size)
                              cr.fill
                          when :none:
                          else raise "The position_indicator of '#{@position_indicator}' is unknown"
                      end
                  end

                  # Draw the text
                  cr.set_source_rgba(*@font_color)
                  layout = cr.create_pango_layout
                  layout.text = text
                  layout.width = width * Pango::SCALE
                  layout.font_description = Pango::FontDescription.new("#{@font_name} #{@font_size}")
                  cr.update_pango_layout(layout)
                  
                  x = text_x
                  y = text_y
                  remaining_height = height
                  layout.lines.each do |line|
                      # Get a rectangle of the text's extents
                      text_rect = line.pixel_extents[1]
                      
                      # Draw the line at the next location
                      cr.move_to(x + text_rect.x, y - text_rect.y)
                      cr.show_pango_layout_line(line)
                      
                      # Move to the next location
                      remaining_height -= text_rect.height
                      y += text_rect.height
                      
                      # Break and skip lines that are not seen
                      break if remaining_height - text_rect.height < 0
                  end
              end
          end
            
          def self.from_xml(parent_container, element)
              new_labels = Labels.new(element.attributes['name'])
                        
              new_labels.position_indicator = (element.attributes['position_indicator'] || :dot).to_sym
              new_labels.spellcheck_style = (element.attributes['spellcheck_style'] || :standard).to_sym
              new_labels.font_name = (element.attributes['font_name'] || 'Arial').to_s
              new_labels.font_size = (element.attributes['font_size'] || 12).to_i
              new_labels.font_color = Helpers::Color.hex_to_rgb(element.attributes['font_color'] ||
                                                    '0x000000FF')
        
                # Add child elements
                element.elements.each do |e|
                    case e.name
                        when "Event": new_labels.add_event(Helpers::Event.from_xml(new_labels, e))
                        when "Binding": Helpers::Binding.from_xml(new_labels, e)
                        else raise "The Labels control does not know how to create a child of type '#{e.name}' from XML."
                    end
                end 

                new_labels.connect_to_container(parent_container)

            new_labels
          end
        end
    end
end
