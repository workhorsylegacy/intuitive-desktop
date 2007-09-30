

module Views
    class View < Base::ContainerParent
      attr_reader :name
      attr_accessor :title, :focused_child, :hotkey_quit
    
      def initialize(program, name, title, pack_style)
            super(pack_style)
        @program = program
        @name = name
        @title = title
        @has_title_bar = true
        
        @focused_child = nil
        @dragging_child = nil
        @drag_by_holding_left_mouse_button = false
      end
    
      def has_title_bar=(value)
          @has_title_bar = value
          
          @program.decorated = @has_title_bar
      end
    
      def has_title_bar
          @has_title_bar
      end    
    
      def drag_by_holding_left_mouse_button=(value)
          @drag_by_holding_left_mouse_button = value
      end
    
      def drag_by_holding_left_mouse_button
          @drag_by_holding_left_mouse_button
      end
    
        def width
            @program.width
        end
    
        def height
            @program.height
        end
    
        def x
            @program.x
        end
    
        def y
            @program.y
        end
    
      def draw(window)
         @children.each { |child|
             child.draw(window)
         }
      end

        def parent_container
            @program
        end

        def on_mouse_down_trigger(x, y, proc)
            @children.each { |child|
                if x >= child.x && y >= child.y &&
                    x < child.right && y < child.bottom
                    child.on_mouse_down_trigger(x, y, proc)
                end
            }       
        end

        def on_mouse_up_trigger(x, y, proc)
            @children.each { |child|
                if x >= child.x && y >= child.y &&
                    x < child.right && y < child.bottom
                    child.on_mouse_up_trigger(x, y, proc)
                end
            }
            
            @dragging_child = nil
        end

        def on_key_press_trigger(key_board_group, modify_keys, key_value)
            # Just return if there is nothing focused
            return unless @focused_child
            
            # Send the key presses to the child
            @focused_child.on_key_press_trigger(key_board_group, modify_keys, key_value)
        end

        def on_mouse_drag_trigger(x, y, button, edge, timestamp)            
            # If we just started dragging, find the control we are in
            unless @dragging_child
                unprocessed_children = self.children.clone
                
                while unprocessed_children.length > 0
                    node = unprocessed_children.pop
                    
                    # Push this node's children on the stack
                    node.children.each { |child| unprocessed_children.push child } if node.respond_to? :children
                    
                    # Determine if this node is the one we are dragging
                    if x >= node.x && y >= node.y && x < node.right && y < node.bottom
                        if node.respond_to? :on_mouse_drag_trigger
                            @dragging_child = node
                            break
                        end
                    end
                end
            end
            
            # Forward the drag to the control that is being dragged
            @dragging_child.on_mouse_drag_trigger(edge, button, x, y, timestamp) if @dragging_child
        end

        def self.from_string(program, xml)
            xml_document = REXML::Document.new(xml)
            new_view = nil
            
            xml_document.elements.each { |element|
                case(element.name)
                    when "View": new_view = View::from_xml(program, element)
                    else raise "A View element was not found in the xml file."
                end
            }  
        
            new_view
        end  
    
      def self.from_xml(program, element)
        new_view = View.new(
                            program,
                  element.attributes['name'],
                  element.attributes['title'], :vertical)
    
        new_view.has_title_bar = (element.attributes['has_title_bar'] || true).to_b
        new_view.drag_by_holding_left_mouse_button = 
            (element.attributes['drag_by_holding_left_mouse_button'] || false).to_b
            
        new_view.hotkey_quit =
            Helpers::MacroFilter.process_keys(element.attributes['hotkey_quit'])
    
        element.elements.each { |e|
          case(e.name)
            when "Container"
                container = Container.from_xml(new_view, e)
                container.connect_to_container(new_view)
          end
        }
    
        new_view
      end
      
        def self.views_from_documents(program, documents)
            views = {}
            
            documents.each do |document|
                view = View.from_string(program, document.data)
                views[view.name] = view
            end
            
            views
        end
      
        # Looks through all the display elements starting with the parent, and returns the one with the matching name
        def self.control_from_element_name(parent, name)
            raise "Parent cannot be nil" unless parent
            
            # Create a stack to hold the unprocessed nodes
            unprocessed_nodes = [parent]
            
            while unprocessed_nodes.length > 0
                # Get a node off the stack
                node = unprocessed_nodes.pop
                
                # Push this node's children on the stack
                node.children.each { |child| unprocessed_nodes.push child } if node.respond_to? :children
                
                # If this node has the correct name, return it
                return node if node.name == name
            end
            
            # If nothing was found return nil
            nil
        end
        
        def all_child_animations
            animations = []
            unprocessed_children = self.children.clone
            while unprocessed_children.length > 0
                node = unprocessed_children.pop
                        
                # Push this node's children on the stack
                node.children.each { |child| unprocessed_children.push child } if node.respond_to? :children
                        
                # If the node is a Drawing, save its Animations
                next unless node.is_a?(Views::Data::Drawing)
                node.animations.each {|animation| animations << animation}
            end
            
            animations
        end
        
        def all_child_layers
            layers = []
            unprocessed_children = self.children.clone
            while unprocessed_children.length > 0
                node = unprocessed_children.pop
                        
                # Push this node's children on the stack
                node.children.each { |child| unprocessed_children.push child } if node.respond_to? :children
                        
                # If the node is a Drawing, save its Layers
                next unless node.is_a?(Views::Data::Drawing)
                node.children.each do |child|
                    layers << child if child.is_a?(Views::Data::Layer)
                end
            end
            
            layers
        end        
    end
end
