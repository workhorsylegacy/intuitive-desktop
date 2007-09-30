
module Views; module Base
    module MixinKeyboard
        attr_accessor :on_key_press_event
        
        def on_key_press_trigger(key_board_group, modify_keys, key_value)
            fire_events :on_key_press_event
        end
    end
end; end
