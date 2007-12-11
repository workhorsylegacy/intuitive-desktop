
require $IntuitiveFramework_Models

module ID; module Models
		class TestUser < Test::Unit::TestCase	    
		    def teardown
            @user.destroy if @user
                
            ID::TestHelper.cleanup()      
		    end
		    
		    def test_can_create
		        public_key, private_key = Models::EncryptionKey.make_public_and_private_keys
		        @user = Models::User.new
		        @user.name = 'Bobrick'
		        @user.public_universal_key = public_key.key.to_s
		        @user.private_key = private_key.key.to_s
		        @user.save!
		        
		        # Make sure we have a valid id
		        assert_not_nil(@user.id)
		        
		        # Make sure the user can be pulled from the database
		        assert_equal(User.find(@user.id).name, @user.name)
		    end
		end
end; end