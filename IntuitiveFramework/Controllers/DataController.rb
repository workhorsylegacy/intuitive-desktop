

module Controllers
  class DataController
        def self.move_to_next_revision(branch)
            # Just return if the current revision is head
            return false unless branch.base_revision_number < branch.head_revision_number
            
            # Move to the next revision
            branch.send(:base_revision_number=, branch.base_revision_number + 1)
            create_workspace_from_revision(branch, branch.base_revision_number)
            
            # Return true if there are more revisions to move to
            return branch.base_revision_number != branch.head_revision_number
        end
        
        def self.move_to_previous_revision(branch)
            # Just return if the current revision is 0
            return false if branch.base_revision_number == 0
            
            # Move to the previous revision
            branch.send(:base_revision_number=, branch.base_revision_number - 1)
            create_workspace_from_revision(branch, branch.base_revision_number)
            
            # Return true if there are more revisions to move to
            return branch.base_revision_number != 0
        end
        
        def self.save_revision(branch)
            # Determine if this is the first revision
            is_first_revision = branch.base_revision_number == -1
            branch.send(:base_revision_number=, 0) if is_first_revision
            
            # Make sure the revision the workspace is based on is up to date
            create_revision_from_deltas(branch, branch.base_revision_number)
            new_delta_number = branch.head_revision_number + 1
            
            # Get the paths of the original, changed, and result folders
            original_folder = "#{branch.folder_name}revisions/#{branch.base_revision_number}/"
            changed_folder = "#{branch.folder_name}workspace/"
            result_folder = "#{branch.folder_name}deltas/"
            
            # Save the differences
            RevisionedFileSystemController.diff_folders(original_folder, changed_folder, result_folder)
            File.delete("#{changed_folder}.file_system_changes") if File.file?("#{changed_folder}.file_system_changes")
        
            # Update the revision number
            branch.send(:base_revision_number=, new_delta_number) unless is_first_revision
            create_revision_from_deltas(branch, branch.base_revision_number)
        end
        
        private
        def self.create_workspace_from_revision(branch, revision_number)
            # Make sure the revision is up to date
            create_revision_from_deltas(branch, revision_number)
            
            # Copy the revision to the workspace
            FileUtils.rm_rf("#{branch.folder_name}workspace/")
            FileUtils::cp_r("#{branch.folder_name}revisions/#{revision_number}/", "#{branch.folder_name}workspace/")
        end
        
        def self.create_revision_from_deltas(branch, revision_number)
            RevisionedFileSystemController.patch_folders("#{branch.folder_name}deltas/", "#{branch.folder_name}revisions/#{revision_number}/", revision_number)
        end
    end
end
