

module ID; module Models
    class TestBranch < Test::Unit::TestCase
        def test_branch_create
            # Create a branch
            user_id = "begin blah blah blah end"
            branch = Branch.new('Cool Project Main', user_id)
            
            # Make sure the properties are correct
            assert_equal(0, branch.base_revision_number)
            assert_equal(0, branch.head_revision_number)
            assert_equal(0, branch.projects.length)
            assert_equal('Cool Project Main', branch.name)
            
            # Make sure properties can change
            branch.name = 'slow project'
            assert_equal('slow project', branch.name)
            
            # Commit changes
            Controllers::DataController.save_revision(branch)
            
            # Make sure the properties are correct
            assert_equal(1, branch.base_revision_number)
            assert_equal(1, branch.head_revision_number)
            assert_equal('slow project', branch.name)
            
            # Move back a revision
            Controllers::DataController.move_to_previous_revision(branch)
            
            # Make sure the properties are correct
            assert_equal(0, branch.base_revision_number)
            assert_equal(1, branch.head_revision_number)
            assert_equal('Cool Project Main', branch.name)
            
            # Move forward a revision
            Controllers::DataController.move_to_next_revision(branch)
            
            # Make sure the properties are correct
            assert_equal(1, branch.base_revision_number)
            assert_equal(1, branch.head_revision_number)
            assert_equal('slow project', branch.name)
        end
        
        def test_branch_from_existing
            # Create a branch
            user_id = "begin blah blah blah end"
            branch = Branch.new('Cool Project Main', user_id)
            
            # Get the existing branch
            new_branch = Branch.from_existing(branch.folder_name)
            
            # Make sure the properties are correct
            assert_equal(branch.branch_number, new_branch.branch_number)
            assert_equal(branch.base_revision_number, new_branch.base_revision_number)
            assert_equal(branch.head_revision_number, new_branch.head_revision_number)
            assert_equal(branch.projects.length, new_branch.projects.length)
            assert_equal(branch.name, new_branch.name)
        end
    end
end; end
