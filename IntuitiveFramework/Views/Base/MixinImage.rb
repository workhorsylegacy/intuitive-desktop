
module ID; module Views; module Base
    module MixinImage
        def draw_image(window)
            cairo_context = window.create_cairo_context
        	   
            # Scale and move the SVG over this control
            svg_pixel_width, svg_pixel_height = self.image.dimensions.to_a
            window_pixel_width, window_pixel_height = window.size
            cairo_context.translate(self.x, self.y)
            cairo_context.scale(self.width.to_f / svg_pixel_width.to_f, self.height.to_f / svg_pixel_height.to_f)
                
            # Draw the SVG
            cairo_context.render_rsvg_handle(self.image)
        end
    end
end; end; end