
require $IntuitiveFramework_Controllers
require $IntuitiveFramework_Servers

module ID; module Controllers
  #FIXME: Rename to TestIdentityController
	class TestUserController < Test::Unit::TestCase
			def setup
          @local_user = UserController::create_user('matt jones')
      end
            
      def teardown
          @local_user.destroy if @local_user
          
          ID::TestHelper.cleanup()
			end
			
			def test_can_prove_identity
          encrypted_proof = Controllers::UserController.create_ownership_test(@local_user.public_universal_key)
          
          decrypted_proof = Controllers::UserController.answer_ownership_test(@local_user.private_key, encrypted_proof)
          
          passed = Controllers::UserController.passed_ownership_test?(@local_user.public_universal_key, decrypted_proof)
          
          assert passed
			end
		end
end; end

