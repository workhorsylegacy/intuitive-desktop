
module Views; module Base
    module MixinContainerParent
        attr_reader :children
        attr_accessor :pack_style
        
    	def child_width
            case(@pack_style)
                when :vertical:
                    self.width
                when :horizontal:
                    return self.width unless @children.length > 0
                    self.width / @children.length
                when :layered:
                    self.width
                else raise "unexpected pack_style of '#{@pack_style}'"
            end
    	end
    	
    	def child_height
            case(@pack_style)
                when :vertical:
                    return self.height unless @children.length > 0
                    self.height / @children.length
                when :horizontal:
                    self.height
                when :layered:
                    self.height                    
                else raise "unexpected pack_style of '#{@pack_style}'"
            end
    	end
    	
    	def child_x(child)
            # Make sure the child is in this container
            raise "That child is not in this container." unless @children.index(child)
    	       	
    	    # Return the X based on the position and pack_style
            case(@pack_style)
                when :vertical:
                    self.x
                when :horizontal:
                    self.x + (@children.index(child) * self.child_width)
                when :layered:
                    self.x                   
                else raise "unexpected pack_style of '#{@pack_style}'"
            end
    	end
    	
    	def child_y(child)
            # Make sure the child is in this container
            raise "That child is not in this container." unless @children.index(child)
    	       	
    	    # Return the Y based on the position and pack_style
            case(@pack_style)
                when :vertical:
                    self.y + (@children.index(child) * self.child_height)
                when :horizontal:
                    self.y
                when :layered:
                    self.y                    
                else raise "unexpected pack_style of '#{@pack_style}'"
            end
    	end
    	
    	def child_right(child)
    	   child_x(child) + child_width
    	end
    	
    	def child_bottom(child)
    	   child_y(child) + child_height
    	end
    end
end; end