
module ID; module Views; module Base
    module MixinBindsToModel
        attr_accessor :property_to_binding_map
        
        def bind_to_models(models, states)
            # Bind all the children
            if self.respond_to? :children
                @children.each do |child|
                    child.bind_to_models(models, states)
                end
            end
            
            return unless @property_to_binding_map
            
            # Hook each binding to a model
            @property_to_binding_map.each do |name, binding|
                model_name = binding.model
                message = "The model '#{model_name}' was not found."
                raise message unless models.has_key?(model_name) || states.has_key?(model_name)
                binding.model = models[model_name] || states[model_name]
                
                # Connect the binding to the Model
                binding.model.bindings << binding
            end
        end
        
        # Adds a binding to the binding map hash
        def add_binding(binding)
            @property_to_binding_map = {} unless @property_to_binding_map
            
            # Make sure the binding is connecting to an existing property
            binding.view_properties.each do |name|
                message = "The Binding cannot bind to the '#{self.class.name}' because it does not have the property '#{name}' and '#{name}='.'"
                raise message unless self.respond_to?(name) && self.respond_to?("#{name}=")

                @property_to_binding_map[name] = binding
            end
        end
        
        # Returns the binding associated with a property or nil
        def binding_for_property(property)
            @property_to_binding_map[property]
        end
    end
end; end; end