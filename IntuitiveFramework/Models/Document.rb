

module Models
    class Document
        attr_reader :parent_project
        
        def initialize(parent_project, name, from_existing = false)
            raise "Parent project cannot be nil" unless parent_project
            @parent_project = parent_project
            
            return if  from_existing
            
            folder = Helpers::FileSystem.get_new_randomly_named_sub_directory("#{@parent_project.folder_name}", "document_")
            @document_number = folder.split('_').last.to_i
            
            Controllers::RevisionedFileSystemController.new_directory(self.workspace_folder, self.folder_name)
            Controllers::RevisionedFileSystemController.new_file(self.workspace_folder, "#{self.folder_name}name")
            Controllers::RevisionedFileSystemController.new_file(self.workspace_folder, "#{self.folder_name}data")
            Controllers::RevisionedFileSystemController.new_file(self.workspace_folder, "#{self.folder_name}run_location")
            Controllers::RevisionedFileSystemController.new_file(self.workspace_folder, "#{self.folder_name}document_type")
                
            # Set the default values
            self.run_location = :server
            self.document_type = :unknown
                
            self.name = name
        end
        
        def folder_name
            "#{@parent_project.folder_name}document_#{@document_number}/"
        end    
        
        def workspace_folder
            @parent_project.workspace_folder
        end
        
        def name
            File.open("#{self.folder_name}name", 'r') { |f| return f.read }
        end
        
        def name=(value)
            File.open("#{self.folder_name}name", 'w') { |f| f.write(value) }
            value
        end    
        
        def data
            File.open("#{self.folder_name}data", 'r') { |f| return f.read }
        end
        
        def data=(value)
            File.open("#{self.folder_name}data", 'w') { |f| f.write(value) }
            value
        end        
        
        def run_location
            File.open("#{self.folder_name}run_location", 'r') { |f| f.read }.to_sym
        end
        
        def run_location=(value)
            # Make sure the value is valid
            new_value = value.to_sym
            valid_values = [:client, :server, :any]
            message = "A document cannot use the value '#{new_value}' for its run location. It can only have the values "
            message += valid_values.collect {|v| "'#{v}'"}.join(', ') + '.'
            raise message unless valid_values.include?(new_value)
            
            File.open("#{self.folder_name}run_location", 'w') { |f| f.write(new_value) }
            new_value
        end
        
        def document_type
            File.open("#{self.folder_name}document_type", 'r') { |f| f.read }.to_sym
        end
        
        def document_type=(value)
            # Make sure the value is valid
            new_value = value.to_sym
            valid_values = [:model, :state, :controller, :view, :unknown]
            message = "A document cannot use the value '#{new_value}' for its document type. It can only have the values "
            message += valid_values.collect {|v| "'#{v}'"}.join(', ') + '.'
            raise message unless valid_values.include?(new_value)
            
            File.open("#{self.folder_name}document_type", 'w') { |f| f.write(new_value) }
            new_value
        end
        
        def self.from_existing(parent_project, folder_name)
            new_document = Document.new(parent_project, nil, true)
            new_document.instance_variable_set("@document_number", folder_name.split('_').last.to_i)
            
            new_document
        end
    end
end