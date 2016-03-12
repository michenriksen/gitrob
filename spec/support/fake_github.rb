require "sinatra/base"

class FakeGitHub < Sinatra::Base
  get "/users/acme" do
    json_response(200, "orgs/acme.json")
  end

  get "/users/acme/repos" do
    json_response(200, "users/acme/repos.json")
  end

  get "/orgs/acme/members" do
    json_response(200, "orgs/acme/members.json")
  end

  get "/users/user1" do
    json_response(200, "users/user1.json")
  end

  get "/users/user1/repos" do
    json_response(200, "users/user1/repos.json")
  end

  get "/users/user2" do
    json_response(200, "users/user2.json")
  end

  get "/users/user2/repos" do
    json_response(200, "users/user2/repos.json")
  end

  get "/users/notfound" do
    error_response(404, "Not Found")
  end

  get "/users/unauthorized" do
    error_response(401, "Unauthorized")
  end

  get "/users/ratelimited" do
    error_response(403, "API rate limit exceeded")
  end

  get "/repos/acme/Hello-World/git/trees/master" do
    json_response(200, "repos/acme/Hello-World/tree.json")
  end

  get "/repos/acme/blocked/git/trees/master" do
    error_response(403, "Repository access blocked")
  end

  get "/repos/acme/empty/git/trees/master" do
    error_response(409, "Git Repository is empty")
  end

  get "/repos/acme/notfound/git/trees/master" do
    error_response(404, "Not Found")
  end

  private

  def json_response(response_code, file_name)
    content_type :json
    status response_code
    File.open(
      File.dirname(__FILE__) + "/fixtures/github/" + file_name, "rb"
    ).read
  end

  def error_response(response_code, message)
    content_type :json
    status response_code
    JSON.generate(:error => message)
  end
end
