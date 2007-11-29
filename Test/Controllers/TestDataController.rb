

=begin
require $IntuitiveFramework_Controllers
require $IntuitiveFramework_Servers

module Controllers
	class TestDataController < Test::Unit::TestCase
			def setup
          # Add a user
          public_key, private_key = Models::EncryptionKey.make_public_and_private_keys
          @user = Models::User.new
          @user.name = 'matt jones'
          @user.public_universal_key = public_key.key.to_s
          @user.private_key = private_key.key.to_s
          @user.save!
      end
            
      def teardown
          @user.destroy if @user
          @communicator.close if @communicator
          @document_server.close if @document_server
          FileUtils.rm_rf($DataSystem)
			end
			
			def test_find_project
          # Create a project
          @branch = Models::Branch.new('Trunk', @user.public_universal_key)		   
          @project = Models::Project.new(@branch, 'Super Cool Thing')

          # Make sure the project can be found by name
          projects = Controllers::DataController.find_projects(:names => [@project.name])
          assert_equal(@project.project_number, projects.first.project_number)
          
          # Make sure the project can be found by the user
          projects = Controllers::DataController.find_projects(:user_ids => [@branch.user_id])
          assert_equal(@project.project_number, projects.first.project_number)
          
          # Make sure the same projects are not duplicated for multiple matches
          projects = Controllers::DataController.find_projects(:user_ids => [@branch.user_id],
                                                                :names => [@project.name])
          assert_equal(1, projects.length)
			end

			def test_find_project_over_network
			   # Create a document server
			   proc = Proc.new { |status, message, exception| raise message }
			   @document_server = Servers::DocumentServer.new('127.0.0.1', 5000, 5001, proc)
			   
			   # Create a communication controller to talk to the server
			   @communicator = Controllers::CommunicationController.new('127.0.0.1', 6000, 6001)
			   @connection = @communicator.create_connection
			   
			   # Create a project on the server
          @branch = Models::Branch.new('Trunk', @user.public_universal_key)
          @project = Models::Project.new(@branch, 'Example Project')

			   # Ask the server for any matching projects
         criteria = {:names => ['Example Project']}
			   projects = Controllers::DataController.find_projects_over_network(
            			                                                       @communicator, 
            			                                                       @connection, 
            			                                                       @document_server.local_connection,
            			                                                       criteria)
			   
			   # Make sure the projects are equal
			   assert_equal(@project.project_number, projects.first.project_number)
			end
		
			def test_can_run_document
			   # Create a document server that throws when it has an error
			   proc = Proc.new do |status, message, exception| 
			       raise exception if exception
			       raise message
			   end
			   @document_server = Servers::DocumentServer.new('127.0.0.1', 5000, 5001, proc)
			   
			   # Create a communication controller to talk to the server
			   @communicator = Controllers::CommunicationController.new('127.0.0.1', 6000, 6001)
			   @connection = @communicator.create_connection
			   
          # Create a project on the server
          @branch = Models::Branch.new('Trunk', @user.public_universal_key)
          @project = Models::Project.new(@branch, 'Example Project')
         
          # Create a Model from XML
          document = Models::Document.new(@project, 'State')
          document.run_location = :server
          document.document_type = :state
          document.data =
<<STATE_XML
                  <Models>
                    <Table name="Blahs">
                      <Column name="name" type="string" allows_null="false" />
                    </Table>
                  </Models>
STATE_XML

          document = Models::Document.new(@project, 'Model')
          document.run_location = :client
          document.document_type = :model
          document.data =
<<MODEL_XML
                  <Models>
              		<Table name="Persons">
              			<Column name="name" type="string" allows_null="false" />
              			<Column name="age" type="integer" allows_null="false" />
              			<Value name="Bobrick" age="67" />
              		</Table>
                  </Models>
MODEL_XML

          # Create a View from XML
          document = Models::Document.new(@project, 'View')
          document.run_location = :client
          document.document_type = :view
          document.data =
<<VIEW_XML
              <View name="main_window" title="Persons Example" pack_style="verical">
                  <Container name="container_main" pack_style="vertical">
                      <Button name="person_name">
                          <Binding name="name"
                              model="Persons"
                              view_properties="text"
                              model_properties="name"
                              on_model_change="save_changes_to_view"
                              on_view_change="do_nothing" />
                          <Event name="on_mouse_up_event"
                              method="manipulate_name"
                              argument="person_name.text"
                              result="Blahs" />                   
                      </Button>
                  </Container>
              </View>
VIEW_XML
          # Create a Controller from Ruby code
          document = Models::Document.new(@project, 'Controller')
          document.run_location = :client
          document.document_type = :controller
          document.data =
<<CONTROLLER_CODE
              class ExampleDocumentController < Controllers::DocumentController
                  def initialize(models)
                      super(models)
                  end
              
                  def manipulate_name(value)
                      value.succ
                  end
              end
CONTROLLER_CODE
              
          # Set the main View and Controller and save the branch
          @project.main_controller_class_name = "ExampleDocumentController"
          @project.main_view_name = "main_window"
          Controllers::DataController.save_revision(@branch)
          
          # Create a  Program to run the Project in
          program = Program.new

          # Have the client download the Project from the server
          project = Controllers::DataController.find_projects_over_network(@communicator,
                                                                         @connection, 
            			                                                       @document_server.local_connection,
                                                                         :names => [@project.name]).first
             
          # Run the Project from the Server
          Controllers::DataController.run_project_over_network(@communicator,
                                                                    @connection,
                                                                    @document_server.local_connection,
                                                                    program,
                                                                    project,
                                                                    project.parent_branch)
      end

      def test_branch
        # Create a simple document with data in it
        data_one = RevisionedDocument.new('secret sauce')
        data_one.commit(:data => "things to buy for supper:\n 1. butter\n 2. crisco\n 3. vegtable oil")
    
        # Branch the first document and change it a little
        data_two = data_one.branch
        data_two.commit(
            :data => "things to buy for dinner:\n 1. butter\n 2. trans fat\n 3. vegtable oil\n 4. powder of fecal",
            :name => 'secret sauce of dinner')
    
        # Make sure the original is not changed
        assert_equal('secret sauce', data_one.head_name)
        assert_equal("things to buy for supper:\n 1. butter\n 2. crisco\n 3. vegtable oil", data_one.head_string)
    
        # Make sure the branch is correct
        assert_equal('secret sauce of dinner', data_two.head_name)
        assert_equal("things to buy for supper:\n 1. butter\n 2. crisco\n 3. vegtable oil", data_two.head_string)
      end

      def test_merge
        # Create a simple document with data in it
        data_one = RevisionData.new('secret sauce', 6)
        data_one.commit(:data => "things to buy for supper:\n 1. butter\n 2. crisco\n 3. vegtable oil")
    
        # Create another document that is a changed version of this one
        data_two = RevisionData.new('secret sauce', 6)
        data_two.commit(:data => "things to buy for supper:\n 1. butter\n 2. crisco\n 3. vegtable oil")
      end     
	end
end

=end