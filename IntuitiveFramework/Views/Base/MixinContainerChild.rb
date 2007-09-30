
module Views; module Base
    module MixinContainerChild
		attr_reader :parent_container

        def x
            return 0 unless @parent_container
            @parent_container.child_x(self)
        end
        
        def y
            return 0 unless @parent_container
            @parent_container.child_y(self)
        end        
        
        def width
            return 0 unless @parent_container
            @parent_container.child_width
        end
        
        def height
            return 0 unless @parent_container 
            @parent_container.child_height
        end
        
        def right
            return 0 unless @parent_container
            @parent_container.child_right(self)
        end
        
        def bottom
            return 0 unless @parent_container 
            @parent_container.child_bottom(self)
        end
        
        def disconnect_from_container()
            raise "There is no parent container." unless @parent_container
            
            @parent_container.children.delete(self)
            @parent_container = nil
        end
        
        def connect_to_container(parent_container)
            # Remove connection to previous parent
            self.disconnect_from_container if @parent_container
             
            # Add connection to new parent
            @parent_container = parent_container
            @parent_container.children << self if @parent_container
        end
    end
end; end
