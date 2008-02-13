
module ID; module Views; module Base
    class ContainerParent
        include MixinBindsToModel
        include MixinContainerParent
        include MixinEvents
        include MixinImage
        include MixinText
        include MixinKeyboard
        include MixinMouse
        include MixinRefresh
            
        def initialize(pack_style)
            @children = []
            @pack_style = pack_style.to_sym
        end
    end
end; end; end
