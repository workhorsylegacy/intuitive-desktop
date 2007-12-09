
module ID; module Views; module Base
    class ContainerParentAndChild
        include MixinBindsToModel
        include MixinContainerParent
        include MixinContainerChild
        include MixinEvents
        include MixinFocus
        include MixinImage
        include MixinKeyboard
        include MixinMouse
        include MixinRefresh        
        include MixinText
            
        def initialize(pack_style)
            @children = []
            @pack_style = pack_style.to_sym
            @parent_container = nil
        end
    end
end; end; end
