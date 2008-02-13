
module ID; module Views; module Base
    module MixinMouse
        attr_accessor :on_mouse_down_event, :on_mouse_up_event

        def on_mouse_down_trigger(x, y, button)
            if self.respond_to? :children
                @children.each do |child|
                    if x >= child.x && x <= child.right &&
                        y >= child.y && y <= child.bottom
                        child.on_mouse_down_trigger(x, y, button)
                        return
                    end
                end
            end
            
            @is_mouse_down = true
            
            self.focus
            
            fire_events :on_mouse_down_event
        end
        	
        def on_mouse_up_trigger(x, y, button)
            if self.respond_to? :children
                @children.each do |child|
                    if x >= child.x && x <= child.right &&
                        y >= child.y && y <= child.bottom
                        child.on_mouse_up_trigger(x, y, button)
                        return
                    end
                end
            end
            
            @is_mouse_down = false
            
            fire_events :on_mouse_up_event
        end
        
        def on_mouse_scroll_trigger(x, y, direction)
            if self.respond_to? :children
                @children.each do |child|
                    if x >= child.x && x <= child.right &&
                        y >= child.y && y <= child.bottom
                        child.on_mouse_scroll_trigger(x, y, direction)
                        return
                    end
                end
            end
            
            fire_events :on_mouse_scroll_trigger
        end
    end
end; end; end
