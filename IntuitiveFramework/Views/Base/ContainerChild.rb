
module ID; module Views; module Base
    class ContainerChild
        include MixinBindsToModel
        include MixinContainerChild
        include MixinEvents
        include MixinFocus
        include MixinImage
        include MixinKeyboard
        include MixinMouse
        include MixinRefresh
        include MixinText
        
        def initialize
            @parent_container = nil
            @is_pressed = false
        end
    end
end; end; end