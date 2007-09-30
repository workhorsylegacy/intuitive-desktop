

module Views
    module Data
        class Layer < Views::Base::ContainerChild
            attr_reader :name, :image
			attr_accessor :offset_x, :offset_y, :rotate
            
            def initialize(name)
                super()
                @name = name
                @image_file = nil
        				@image = nil
        				@offset_x = 0
        				@offset_y = 0
                @rotate = 0
            end
    
	        def x
	            return 0 unless @parent_container
	            @parent_container.x
	        end
	        
	        def y
	            return 0 unless @parent_container
	            @parent_container.y
	        end        
	        
	        def width
	            return 0 unless @parent_container
	            @parent_container.width
	        end
	        
	        def height
	            return 0 unless @parent_container 
	            @parent_container.height
	        end
	        
	        def right
	            return 0 unless @parent_container
	            @parent_container.right
	        end
	        
	        def bottom
	            return 0 unless @parent_container 
	            @parent_container.bottom
	        end

			def offset_x_number
				if @offset_x[-1..-1] == '%'
					@offset_x[0..-2].strip.to_f / 100.0
				elsif @offset_x.is_a?(Float) || @offset_x.is_a?(Fixnum)
					@offset_x.strip.to_f				
				else
					0
				end
			end

			def offset_y_number
				if @offset_y[-1..-1] == '%'
					@offset_y[0..-2].strip.to_f / 100.0
				elsif @offset_y.is_a?(Float) || @offset_y.is_a?(Fixnum)
					@offset_y.strip.to_f				
				else
					0
				end
			end

            def image_file
                # Update the property if it gets changes from the model
                if @property_to_binding_map && @property_to_binding_map.has_key?(:image_file)
                    binding = @property_to_binding_map[:image_file]
                    if binding.on_model_change == :save_changes_to_view
                        data = @property_to_binding_map[:image_file].get_model_data.first.first
                        if @old_model_image_file != data
                            @image_file = data
							@image = RSVG::Handle.new_from_file(@image_file)
                            @old_model_image_file = data
                        end
                    end
                end
                
                # Return the property
                @image_file
            end
            
			def image_file=(value)
				# Save the new value
              	@image_file = value
				@image = RSVG::Handle.new_from_file(@image_file) if @image_file
              
             	# Update the model if it gets changes from the view
              	if @property_to_binding_map && @property_to_binding_map.has_key?(:image_file)
                  	binding = @property_to_binding_map[:image_file]
                  	if binding.on_view_change == :save_changes_to_model
                      	binding.set_model_data(:image_file, value)
                  	end
              	end
			end
    
			def draw(cr, window, zoom)
                return unless self.image_file

	            cairo_context = window.create_cairo_context
	        	   
	            # Scale and move the SVG over this control
	            svg_pixel_width, svg_pixel_height = self.image.dimensions.to_a
	            window_pixel_width, window_pixel_height = window.size
	            cairo_context.translate(self.x, self.y)
				cairo_context.translate(self.offset_x_number * self.width, self.offset_y_number * self.height)
	            cairo_context.scale(self.width.to_f / svg_pixel_width.to_f, self.height.to_f / svg_pixel_height.to_f)
	                
              # Rotate the Layer
              # FIXME: Add real PI here using the Ruby Math library
              cairo_context.rotate(3.1459/180.0 * @rotate) if @rotate != 0
                  
	            # Draw the SVG
	            cairo_context.render_rsvg_handle(self.image)
        	end 
          
          def self.from_xml(parent_container, element)
                new_layer = Layer.new(element.attributes['name'])
        
                # Add attributes
                new_layer.image_file = element.attributes['image_file']
				new_layer.offset_x = element.attributes['offset_x'] || '0'
				new_layer.offset_y = element.attributes['offset_y'] || '0'

                # Add child elements
                element.elements.each do |e|
                    case e.name
                        when "Event": new_layer.add_event(Helpers::Event.from_xml(new_layer, e))
                        when "Binding": Helpers::Binding.from_xml(new_layer, e)
                        else raise "The Layer does not know how to create a child of type '#{e.name}' from XML."
                    end
                end                
        
                new_layer.connect_to_container(parent_container)
            
                new_layer
          end
        end
    end
end
