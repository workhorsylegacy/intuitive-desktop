
module Views; module Base
    module MixinText
            def text
                # Update the property if it gets changes from the model
                if @property_to_binding_map && @property_to_binding_map.has_key?(:text)
                    binding = @property_to_binding_map[:text]
                    if binding.on_model_change == :save_changes_to_view
                        data = @property_to_binding_map[:text].get_model_data.first
                        if @old_model_text != data
                            @old_model_text = data
                            @text = data
                        end
                    end
                end
                
                # Return the property
                return @text.join(', ') if @text.is_a?(Array)
                @text.to_s
            end
            
          def text=(value)
              # Save the new value
              @text = value  
              
              # Update the model if it gets changes from the view
              if @property_to_binding_map && @property_to_binding_map.has_key?(:text)
                  binding = @property_to_binding_map[:text]
                  if binding.on_view_change == :save_changes_to_model
                      binding.set_model_data(:text, value)
                  end
              end

              self.on_text_changed_trigger
              self.refresh
          end
        
        def on_text_changed_trigger
            fire_events :on_text_changed_event
        end
            
        def draw_text(window)
            cairo_context = window.create_cairo_context
            
            # Create the text to be drawn
            cairo_context.set_source_rgba(*@font_color)
            layout = cairo_context.create_pango_layout
            
            unless self.respond_to? :text_or_default
                layout.text = self.text
            else
                if self.text_or_default == nil
                    layout.text = "blank"
                else
                    layout.text = self.text_or_default.to_s
                end
            end

            layout.width = self.width * Pango::SCALE
            layout.font_description = Pango::FontDescription.new("#{@font_name} #{@font_size}")
            cairo_context.update_pango_layout(layout)
                    
            # Draw the text
            x = self.x
            y = self.y
            remaining_height = self.height
            layout.lines.each do |line|
                # Get a rectangle of the text's extents
                text_rect = line.pixel_extents[1]
                
                # Draw the line at the next location
                cairo_context.move_to(x + text_rect.x, y - text_rect.y)
                cairo_context.show_pango_layout_line(line)
                
                # Move to the next location
                remaining_height -= text_rect.height
                y += text_rect.height
                
                # Break and skip lines that are not seen
                break if remaining_height - text_rect.height < 0
            end
        end        
    end
end; end
