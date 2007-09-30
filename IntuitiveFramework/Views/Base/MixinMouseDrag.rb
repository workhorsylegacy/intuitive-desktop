
module Views; module Base
    module MixinMouseDrag
        attr_accessor :on_mouse_drag_event, :scroll_position

        def on_mouse_drag_trigger(edge, button, x, y, timestamp)
            # Scroll to the position and refresh
            self.scroll_position = [-(x - self.x), -(y - self.y)]
            
            # Fire any events
            fire_events :on_mouse_drag_event
            
            self.refresh
        end
    end
end; end
