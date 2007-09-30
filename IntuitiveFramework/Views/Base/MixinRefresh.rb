
module Views; module Base
    module MixinRefresh
        def refresh
            # Find the parent program
            parent = @parent_container
            while parent.respond_to? :parent_container
                parent = parent.parent_container
            end
            
            # Tell the program to refresh this control
            parent.child_refresh(self)
        end
    end
end; end
