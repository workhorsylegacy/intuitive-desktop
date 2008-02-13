

module ID; module Views; module Data
        class Line < Views::Base::ContainerChild
            attr_reader :name
            attr_accessor :color, :join, :cap, :width, :highlight_color
            
            def initialize(name)
                super()
                @name = name
                @highlight_width = 0
                @points = []
            end
    
            def points
                # Update the property if it gets changes from the model
                if @property_to_binding_map && @property_to_binding_map.has_key?(:points)
                    binding = @property_to_binding_map[:points]
                    if binding.on_model_change == :save_changes_to_view
                        data = @property_to_binding_map[:points].get_model_data
                        if @old_model_points != data
                            @points = data
                            @old_model_points = data
                        end
                    end
                end
                
                # Return the property
                @points
            end
            
          def points=(value)
              # Save the new value
              @points = value  
              
              # Update the model if it gets changes from the view
              if @property_to_binding_map && @property_to_binding_map.has_key?(:points)
                  binding = @property_to_binding_map[:points]
                  if binding.on_view_change == :save_changes_to_model
                      binding.set_model_data(:points, value)
                  end
              end
          end
            
            def highlight_width
                # Update the property if it gets changes from the model
                if @property_to_binding_map && @property_to_binding_map.has_key?(:highlight_width)
                    binding = @property_to_binding_map[:highlight_width]
                    if binding.on_model_change == :save_changes_to_view
                        data = @property_to_binding_map[:highlight_width].get_model_data.first.first
                        if @old_model_highlight_width != data
                            @old_model_highlight_width = data
                            @highlight_width = data
                        end
                    end
                end
                
                # Return the property
                @highlight_width
            end
            
          def highlight_width=(value)
              # Save the new value
              @highlight_width = value  
              
              # Update the model if it gets changes from the view
              if @property_to_binding_map && @property_to_binding_map.has_key?(:highlight_width)
                  binding = @property_to_binding_map[:highlight_width]
                  if binding.on_view_change == :save_changes_to_model
                      binding.set_model_data(:highlight_width, value)
                  end
              end
          end
    
          def draw(cairo_context, window, zoom)
              coordinates = self.points

              # Get an array that holds the color, width, cap, and join for the regular and highlighted line
              line_width_and_color = [
                                        [@highlight_color,  2 * self.highlight_width + @width, @cap, @join], 
                                        [@color, @width, @cap, @join]
                                     ]
              
              # Draw the line regular and highlighted
              line_width_and_color.each do |color, width, cap, join|
                  cairo_context.set_source_rgba(*color)
                  cairo_context.line_width = width
                  cairo_context.line_cap = cap_to_number(cap)
                  cairo_context.line_join = join_to_number(join)
                  
                  # Draw each of the coordinates as connecting lines
                  drew_first_point = false
                  coordinates.each do |point|
                      if drew_first_point
                          cairo_context.line_to(point[0], point[1])
                      else
                          cairo_context.move_to(point[0], point[1])
                          drew_first_point = true
                      end
                  end
                  cairo_context.stroke
              end
          end   
          
          def self.from_xml(parent_container, element)
                new_line = Line.new(element.attributes['name'])
        
                # Add attributes
                new_line.color = Helpers::Color.hex_to_rgb(
                                            element.attributes['color'] ||
                                            '0xFFFFFFFF')
                new_line.highlight_color = Helpers::Color.hex_to_rgb(
                                              element.attributes['highlight_color'] ||
                                              '0x000000FF')
                new_line.join = (element.attributes['join'] || :round).to_sym
                new_line.cap = (element.attributes['cap'] || :round).to_sym
                new_line.width = (element.attributes['width'] || '1.0').to_f
                new_line.highlight_width = (element.attributes['highlight_width'] || '0.0').to_f

                # Add child elements
                element.elements.each do |e|
                    case e.name
                        when "Event": new_line.add_event(Helpers::Event.from_xml(new_line, e))
                        when "Binding": Helpers::Binding.from_xml(new_line, e)
                        else raise "The Line does not know how to create a child of type '#{e.name}' from XML."
                    end
                end                
        
                new_line.connect_to_container(parent_container)
            
                new_line
          end
          
          def cap_to_number(cap_name)
              case cap_name
                  when :butt : Cairo::LINE_CAP_BUTT
                  when :round : Cairo::LINE_CAP_ROUND
                  when :square : Cairo::LINE_CAP_SQUARE
                  else raise "No cap named '#{cap_name.to_s}'."
              end
          end
          
          def join_to_number(join_name)
              case join_name
                  when :bevel : Cairo::LINE_JOIN_BEVEL
                  when :miter : Cairo::LINE_JOIN_MITER
                  when :round : Cairo::LINE_JOIN_ROUND
                  else raise "No cap named '#{join_name.to_s}'."
              end
          end
        end
end; end; end
