

module Models
    class TestDocument < Test::Unit::TestCase
        def setup
            # Create a branch
            user_id = "begin blah blah blah end"
            @branch = Branch.new('Cool Project Main', user_id)
            @project = Project.new(@branch, 'Cool Project')
        end
        
        def test_document_create
            # Create a document
            document = Document.new(@project, 'magic view')
            
            # Make sure the document was created
            assert_same(@project, document.parent_project)
            assert_equal(1, @project.documents.length)
            
            # Make sure the properties are corect
            assert_equal('magic view', document.name)
            assert_equal('', document.data)
            assert_equal(:server, document.run_location)
            assert_equal(:unknown, document.document_type)
            
            # Change the properties and make sure they are updated
            document.name = "scientific view"
            document.data = "<View title=\"example view\" />"
            document.run_location = :client
            document.document_type = :view
            assert_equal('scientific view', document.name)
            assert_equal("<View title=\"example view\" />", document.data)
            assert_equal(:client, document.run_location)
            assert_equal(:view, document.document_type)
        end
    end
end