require File.dirname(__FILE__) + '/../test_helper'
require 'projects_controller'

class ProjectsController; def rescue_action(e) raise e end; end

class ProjectsControllerApiTest < Test::Unit::TestCase
  def setup
    @controller = ProjectsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_search_projects
    result = invoke :search_projects
    assert_equal nil, result
  end

  def test_register_project
    result = invoke :register_project
    assert_equal nil, result
  end

  def test_register_identity
    result = invoke :register_identity
    assert_equal nil, result
  end

  def test_search_identities
    result = invoke :search_identities
    assert_equal nil, result
  end
end
