
module Views; module Base
    module MixinFocus
        def focus
            # If there are children, focus on the first child
            if self.respond_to? :children
                @children.first.focus if @children.length > 0
                return
            end

            # Find the parent program
            parent = @parent_container
            while parent.respond_to? :parent_container
                parent = parent.parent_container
            end
                
            # Tell the view to focus on this control
            parent.main_view.focused_child = self
        end
        
        def is_focused?
            # Find the parent program
            parent = @parent_container
            while parent.respond_to? :parent_container
                parent = parent.parent_container
            end
            
            return parent.main_view.focused_child == self
        end
        
        # Draw a highlight if this control is focused
        def draw_focus_highlight(window)
            if self.is_focused?
                cr = window.create_cairo_context
                    
                cr.set_source_rgba(249.0/256.0, 131.0/256.0, 16.0/256.0, 0.4)
                cr.set_line_width(10)
                cr.rectangle(self.x+5, self.y+5, self.width-10, self.height-10)
                cr.stroke
            end
        end
    end
end; end