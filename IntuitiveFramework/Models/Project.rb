

module Models
    class Project
        attr_reader :parent_branch, :project_number
        
        def initialize(parent_branch, name, from_existing = false)
            @parent_branch = parent_branch
            
            return if from_existing

            folder = Helpers::FileSystem.get_new_randomly_named_sub_directory(self.workspace_folder, "project_")
            @project_number = folder.split('_').last.to_i
            
            Controllers::RevisionedFileSystemController.new_directory(self.workspace_folder, self.folder_name)
            Controllers::RevisionedFileSystemController.new_file(self.workspace_folder, "#{self.folder_name}name")
            Controllers::RevisionedFileSystemController.new_file(self.workspace_folder, "#{self.folder_name}main_controller_class_name")
            Controllers::RevisionedFileSystemController.new_file(self.workspace_folder, "#{self.folder_name}main_view_name")
                
            self.name = name
        end
        
        def folder_name
            "#{self.workspace_folder}project_#{@project_number}/"
        end
        
        def workspace_folder
            @parent_branch.workspace_folder
        end
        
        def name
            File.open("#{self.folder_name}name", 'r') { |f| return f.read }
        end
        
        def name=(value)
            File.open("#{self.folder_name}name", 'w') { |f| f.write(value) }
            value
        end
        
        def description
            File.open("#{self.folder_name}description", 'r') { |f| return f.read }
        end
        
        def description=(value)
            File.open("#{self.folder_name}description", 'w') { |f| f.write(value) }
            value
        end        
        
        def main_controller_class_name
            File.open("#{self.folder_name}main_controller_class_name", 'r') { |f| return f.read }
        end
        
        def main_controller_class_name=(value)
            File.open("#{self.folder_name}main_controller_class_name", 'w') { |f| f.write(value) }
            value
        end        
        
        def main_view_name
            File.open("#{self.folder_name}main_view_name", 'r') { |f| return f.read }
        end
        
        def main_view_name=(value)
            File.open("#{self.folder_name}main_view_name", 'w') { |f| f.write(value) }
            value
        end          
        
        # Returns all the documents in the workspace
        def documents
            # Create a document object for each project file
            (Dir.entries(self.folder_name) - ['.', '..']).collect do |entry|
                next unless File.directory?("#{self.folder_name}#{entry}/") && entry.split('_').first == "document"
                
                Document.from_existing(self, "#{self.folder_name}#{entry}/")
            end.compact
        end
        
        def document_models
            documents.select { |d| d.document_type == :model }
        end
        
        def document_views
            documents.select { |d| d.document_type == :view }
        end        
        
        def document_controllers
            documents.select { |d| d.document_type == :controller }
        end        
        
        def document_states
            documents.select { |d| d.document_type == :state }
        end   
        
        def self.from_existing(parent_branch, folder_name)
            new_project = Project.new(parent_branch, nil, true)
            new_project.instance_variable_set("@project_number", folder_name.split('_').last.to_i)
            
            new_project
        end
        
        def self.from_number(branch, number)
            number = number.to_i
            branch.projects.each do |project|
                return project if project.project_number == number
            end
            
            raise "No Project with the number '#{number}' found."
        end
    end
end