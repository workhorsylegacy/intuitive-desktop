
    class Program < Gtk::EventBox
        attr_reader :parent_window, :view_file
        attr_accessor :models, :views, :controllers, :states, :main_view, :main_controller
    
        def initialize(parent_window)
            super()
            
            @parent_window = parent_window
            @controllers = {}
            @views = {}
            @models = {}
            @states = {}
            @main_view = nil
            @main_controller = nil
    
            signal_connect('expose-event') do |widget, event|
                self.draw
            end
    
            signal_connect("event") do |widget, event|
                if event.event_type.name == 'GDK_SCROLL' && @main_view
                    case event.direction
                        when Gdk::EventScroll::Direction::DOWN
                            @main_view.on_mouse_scroll_trigger(event.x, event.y, :down)
                        when Gdk::EventScroll::Direction::UP
                            @main_view.on_mouse_scroll_trigger(event.x, event.y, :up)
                    end
                end
            end
    
            signal_connect("button_press_event") do |widget, event|
                @dragging = true
    
                @main_view.on_mouse_down_trigger(event.x, event.y, event.button) if @main_view
                self.draw
            end
    
            signal_connect("button_release_event") do |widget, event|
                @dragging = false
    
                @main_view.on_mouse_up_trigger(event.x, event.y, event.button) if @main_view
                self.draw
            end
        
            signal_connect("motion_notify_event") do |widget, event|
                @main_view.on_mouse_drag_trigger(event.x, event.y) if @dragging
            end
            
            signal_connect("key_press_event") do |widget, event|
                return unless @main_view
    
                # Get the modifier keys into a hash
                modify_keys = {:control => event.state.control_mask?,
                                :shift => event.state.shift_mask?}
                
                    # Get the key values into letters
                # FIXME: There HAS to be a smarter way to do this. Pango? How does GTk do it?
                # FIXME: Just finnish for now
                key_to_char = { 97 => 'a',
                                98 => 'b',
                                99 => 'c',
                                100 => 'd',
                                101 => 'e',
                                102 => 'f',
                                103 => 'g',
                                104 => 'h',
                                105 => 'i',
                                106 => 'j',
                                107 => 'k',
                                108 => 'l',
                                109 => 'm',
                                110 => 'n',
                                111 => 'o',
                                112 => 'p',
                                113 => 'q',
                                114 => 'r',
                                115 => 's',
                                116 => 't',
                                117 => 'u',
                                118 => 'v',
                                119 => 'w',
                                120 => 'x',
                                121 => 'y',
                                122 => 'z',
                                65288 => :backspace,
                                65289 => :tab,
                                32 => :space}
                                
                                
                    key_value = key_to_char[event.keyval]
                    key_value = '#' unless key_value
                
                # Get the keyboard group
                key_board_group = event.group
                
                @main_view.on_key_press_trigger(key_board_group, modify_keys, key_value)
            end
          end
    
        def draw
            @main_view.draw(self.window) if @main_view
        end
    
        def child_refresh(child)
            # FIXME: Does this even do anything?
            queue_draw_area(child.x, child.y, child.right, child.bottom)
            
            child.draw(self.window)
        end
    
        def width
            @parent_window.width
        end
        
        def height
            @parent_window.height
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
      end
        
        def name
            @main_view.title
        end
    end