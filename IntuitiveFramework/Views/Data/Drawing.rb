
module Views
    module Data
        class Drawing < Views::Base::ContainerParentAndChild
            attr_reader :name
            attr_accessor :color
            
            include Views::Base::MixinMouseDrag
            
            def initialize(name)
                super('vertical')
                @name = name
                @scroll_position = [0, 0]
                @zoom = 1.0
            end
            
            def min_width
                10
            end
            
            def min_height
                10
            end          
            
            def scroll_position
                # Update the property if it gets changes from the model
                if @property_to_binding_map && @property_to_binding_map.has_key?(:scroll_position)
                    binding = @property_to_binding_map[:scroll_position]
                    if binding.on_model_change == :save_changes_to_view
                        data = @property_to_binding_map[:scroll_position].get_model_data.first || [0, 0]
                        if @old_model_scroll_position != data
                            @old_model_scroll_position = data
                            @scroll_position = data
                        end
                    end
                end
                
                # Return the property
                @scroll_position
            end
            
          def scroll_position=(value)
              # Save the new value
              @scroll_position = value  
              
              # Update the model if it gets changes from the view
              if @property_to_binding_map && @property_to_binding_map.has_key?(:scroll_position)
                  binding = @property_to_binding_map[:scroll_position]
                  if binding.on_view_change == :save_changes_to_model
                      binding.set_model_data(:scroll_position, value)
                  end
              end

              self.refresh
          end
    
            def zoom
                # Update the property if it gets changes from the model
                if @property_to_binding_map && @property_to_binding_map.has_key?(:zoom)
                    binding = @property_to_binding_map[:zoom]
                    if binding.on_model_change == :save_changes_to_view
                        data = @property_to_binding_map[:zoom].get_model_data.first || 1.0
                        if @old_model_zoom != data
                            @old_model_zoom = data
                            @zoom = data
                        end
                    end
                end
                
                # Return the property
                @zoom
            end
            
          def zoom=(value)
              # Save the new value
              @zoom = value if value >= 0.1
              
              # Update the model if it gets changes from the view
              if @property_to_binding_map && @property_to_binding_map.has_key?(:zoom)
                  binding = @property_to_binding_map[:zoom]
                  if binding.on_view_change == :save_changes_to_model
                      binding.set_model_data(:zoom, value)
                  end
              end

              self.refresh
          end
    
          def on_mouse_scroll_trigger(x, y, direction)
              case direction
                  when :up: self.zoom -= 0.05
                  when :down: self.zoom += 0.05
              end
          end
    
          def draw(window)
              cr = window.create_cairo_context                         
                          
              # Move to the top left of this control
              cr.translate(self.x, self.y)
            
              cr.rectangle(0, 0, self.width, self.height)
              cr.clip            
            
              # Fill the background
              cr.set_source_rgba(*@color)
              cr.rectangle(0, 0, self.width, self.height)
              cr.fill
              
              # Move to the center of this control
              scroll_x, scroll_y = self.scroll_position
              center_x = self.width * 0.5
              center_y = self.height * 0.5
              cr.translate(center_x - scroll_x, center_y - scroll_y)
              cr.scale(zoom, zoom)              
              
              # Draw all the children over the blank surface
              @children.each do |child|
                  child.draw(cr, window, zoom)
              end
          end
          
          def self.from_xml(parent_container, element)
              new_drawing = Drawing.new(element.attributes['name'])

              new_drawing.color = Helpers::Color.hex_to_rgb(element.attributes['color'])

              # Add child elements
              element.elements.each do |e|
                  case(e.name)
                      when "Line": Views::Data::Line.from_xml(new_drawing, e)
                      when "Labels": Labels.from_xml(new_drawing, e)
                      when "Polygon": Views::Data::Polygon.from_xml(new_drawing, e)
                      when "Event": new_drawing.add_event(Helpers::Event.from_xml(new_drawing, e))
                      when "Binding": Helpers::Binding.from_xml(new_drawing, e)
                      else raise "The Drawing does not know how to create a child of type '#{e.name}' from XML."
                  end
              end

              new_drawing.connect_to_container(parent_container)
            
              new_drawing
          end         
        end
    end
end
