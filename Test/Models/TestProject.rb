

module Models
    class TestProject < Test::Unit::TestCase
        def setup
            # Create a branch
            user_id = "begin blah blah blah end"
            @branch = Branch.new('Cool Project Main', user_id)   
        end
        
        def test_project_create
            # Create a project
            project = Project.new(@branch, 'Cool Project')
            
            # Make sure the project was created
            assert_same(@branch, project.parent_branch)
            assert_equal(1, @branch.projects.length)

            # Make sure the project's properties are correct
            assert_equal('Cool Project', project.name)
            assert_equal('', project.main_controller_class_name)
            assert_equal(0, project.documents.length)
            
            # Change the properties and make sure they are updated
            project.name = "Warm project"
            project.main_controller_class_name = 'go'
            assert_equal('Warm project', project.name)
            assert_equal('go', project.main_controller_class_name)
        end
    end
end