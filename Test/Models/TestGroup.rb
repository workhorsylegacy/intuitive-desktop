
require $IntuitiveFramework_Models

module ID; module Models
		class TestGroup < Test::Unit::TestCase
		    def setup
                public_key, private_key = Models::EncryptionKey.make_public_and_private_keys
		        @user = User.new
		        @user.name = 'Bobrick'
		        @user.public_universal_key = public_key.key.to_s
		        @user.private_key = private_key.key.to_s
		        @user.save!
		    end
		    
		    def teardown
		        @user.destroy if @user
		        @group.destroy if @group
		    end
		    
		    def test_can_create
		        # Create a Group
		        @group = Group.new
		        @group.name = 'pair programming'
		        @group.save!
		        
		        # Make sure the Group was really saved
		        assert_not_nil(@group.id)
		        assert_equal(Group.find(@group.id).name, @group.name)
		        
		        # Make sure the group contains the user
		        @group.users << @user
		        @group.update
		        assert_equal(@group.users.first, @user)
		        
		        # Make sure the user is in the group
		        assert_equal(@user.groups.first, @group)
		    end
		end
end; end