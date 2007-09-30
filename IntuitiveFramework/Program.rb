
    class Program < Gtk::Window
        attr_reader :view_file
        attr_accessor :models, :views, :controllers, :states, :main_view, :main_controller
    
        def initialize
            super()
            
            @controllers = {}
            @views = {}
            @models = {}
            @states = {}
            @main_view = nil
            @main_controller = nil
            @dragging = {}
    
            self.title = 'Intuitive Desktop'
    
            # Have the Desktop full screen when first opening
            self.set_size_request(
                    Models::System::Resolution.width,
                    Models::System::Resolution.height)
    
            # Have this Gtk Window listen for ALL events
            self.add_events(Gdk::Event::ALL_EVENTS_MASK)
    
            # End the program when they close the Desktop window
            signal_connect("destroy") do
                Gtk.main_quit
            end
    
            signal_connect("screen_changed") do |widget, event|
                on_screen_changed(widget, event)
            end
            on_screen_changed(self, nil)

            self.set_app_paintable(true)
    
            self.signal_connect('expose_event') do |widget, event|
                self.draw
            end
    
            self.signal_connect("event") do |widget, event|
                if event.event_type.name == 'GDK_SCROLL' && @main_view
                    case event.direction
                        when Gdk::EventScroll::Direction::DOWN
                            @main_view.on_mouse_scroll_trigger(event.x, event.y, :down)
                        when Gdk::EventScroll::Direction::UP
                            @main_view.on_mouse_scroll_trigger(event.x, event.y, :up)
                    end
                end
            end
    
            self.signal_connect("button_press_event") do |widget, event|
                @dragging[event.button] = true
    
                # Trigger all the mouse down events for children
                @main_view.on_mouse_down_trigger(event.x, event.y, event.button) if @main_view
                
                # Begin dragging the Program if they are holding the drag button
                if @main_view.drag_by_holding_left_mouse_button
                    self.begin_move_drag(event.button,
                                  event.x_root, event.y_root, event.time)
                end                
                
                self.schedule_draw
            end
    
            self.signal_connect("button_release_event") do |widget, event|
                @dragging[event.button] = false
    
                @main_view.on_mouse_up_trigger(event.x, event.y, event.button) if @main_view
                self.schedule_draw
            end
        
            self.signal_connect("motion_notify_event") do |widget, event|
                # Drag the View if this is the drag button
                if @drag_by_holding_surface_button == 1
                    @program.begin_move_drag(button, x, y, timestamp)
                else
                    if @dragging.has_key?(1) && @dragging[1]
                        @main_view.on_mouse_drag_trigger(event.x, event.y, nil, nil, nil)
                    end
                end
            end
            
            self.signal_connect("key_press_event") do |widget, event|
                return unless @main_view

                # Get the modifier keys into a hash
                modify_keys = {:control => event.state.control_mask?,
                                :shift => event.state.shift_mask?,
                                :alt => event.state.mod1_mask?}

                # Get the key values into letters
                # FIXME: There HAS to be a smarter way to do this. Pango? How does GTk do it?
                # FIXME: Just finnish for now
                key_to_char = { 97 => :a,
                                98 => :b,
                                99 => :c,
                                100 => :d,
                                101 => :e,
                                102 => :f,
                                103 => :g,
                                104 => :h,
                                105 => :i,
                                106 => :j,
                                107 => :k,
                                108 => :l,
                                109 => :m,
                                110 => :n,
                                111 => :o,
                                112 => :p,
                                113 => :q,
                                114 => :r,
                                115 => :s,
                                116 => :t,
                                117 => :u,
                                118 => :v,
                                119 => :w,
                                120 => :x,
                                121 => :y,
                                122 => :z,
                                65288 => :backspace,
                                65289 => :tab,
                                32 => :space,
                                65307 => :escape,
                                65513 => :alt,
                                65507 => :ctrl,
                                65505 => :shift}
                                
                    keys = [key_to_char[event.keyval] || :"#"]
                    key_value = keys.first
                    
                    # Add modifier keys
                    keys << :ctrl if event.state.control_mask?
                    keys << :shift if event.state.shift_mask?
                    keys << :alt if event.state.mod1_mask?
                    
                    keys.sort!
                
                # Fire any hotkey events
                if @main_view.hotkey_quit
                    @main_view.hotkey_quit.each do |h|
                        Gtk.main_quit if h == keys
                    end
                end
                
                # Get the keyboard group
                key_board_group = event.group
                
                @main_view.on_key_press_trigger(key_board_group, modify_keys, key_value)
            end
          end
    
        def draw
            # Make the window transparent.
            cr = self.window.create_cairo_context
            cr.set_source_rgba(1.0, 1.0, 1.0, 0.0)
        
            cr.set_operator(Cairo::OPERATOR_SOURCE)
            cr.paint

            @main_view.draw(self.window)
            
#            return unless self.window.respond_to? :input_shape_combine_mask
#            pm = Gdk::Pixmap.new(nil, width, height, 1)
#            pmcr = pm.create_cairo_context
#            pmcr.arc(100.0, 100.0, 0.5, 0, 2.0*3.14)
#            pmcr.fill
#            pmcr.stroke
#            # Apply input mask
#            self.window.input_shape_combine_mask(pm, 0, 0)
        end
    
        def schedule_draw
            self.queue_draw
        end
    
        def child_refresh(child)
            # FIXME: Does this even do anything?
            queue_draw_area(child.x, child.y, child.right, child.bottom)
            
            child.draw(self.window)
        end
    
        def width
            self.size.first
        end
        
        def height
            self.size.last
        end
    
        def mouse_x
            @main_view.pointer.first
        end
        
        def mouse_y
            @main_view.pointer.last
        end 
    
        def x
            0
        end
    
        def y
            0
        end
      
        def setup_bindings
              # Bind the model to the view
              @main_view.bind_to_models(@models, @states)
          
              # Bind the events to the view
              @main_view.bind_to_events(@models, @states, @main_view, @main_controller)
              
              # Connect Animations to Layers
              layers = @main_view.all_child_layers
              animations = @main_view.all_child_animations
              animations.each do |animation|
                  animation.actions.each do |action|
                      action.children.each do |child|
                          child_layers = child.layers.clone
                          child.instance_variable_set("@layers", [])
                          child_layers.each do |child_layer|
                              found_it = false
                              layers.each do |layer|
                                 child.layers << layer if layer.name == child_layer
                                 found_it = true
                              end
                              
                              message = "A Layer named '#{child_layer}' was not found for the Animation '#{action.name}' to connect to"
                              raise message unless found_it
                          end
                      end
                  end
              end
              
              # Set the default properties of any Layers connected to Animations
              animations.each do |animation|
                  animation.actions.each do |action|
                      action.children.each do |child|
                          case child.class.name
                              when "Views::Animations::Rotate":
                                  child.layers.each do |layer|
                                      layer.rotate = child.degree_start
                                  end
                          end
                      end
                  end
              end
        end
        
        def name
            @main_view.title
        end
        
        def run()
            # Initialize Gtk
            Gtk.init

            # Start all the Animations
            animations = @main_view.all_child_animations
            animations.each do |animation|
                animation.start_animation(self)
            end
        
            # Run the program
            self.show_all
            Gtk.main
        end        
        
        private
        
    def on_screen_changed(widget, event)
        screen = widget.screen
        colormap = screen.rgba_colormap
  
        if colormap == nil
            colormap = screen.rgb_colormap
        end
  
        widget.set_colormap(colormap)
        return false
    end
end
