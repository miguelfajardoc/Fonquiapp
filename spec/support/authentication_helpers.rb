# Every page requires a signed-in user, so request specs sign one in by default.
# Tag an example or group with :signed_out to exercise the signed-out experience.
module AuthenticationHelpers
  # Sets the signed session cookie directly (like Rails' generated SessionTestHelper),
  # so specs neither depend on the login form nor count against its rate limit.
  def sign_in_as(user)
    session = user.sessions.create!
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = session.id
      cookies["session_id"] = cookie_jar[:session_id]
    end
    user
  end

  def sign_out
    cookies.delete("session_id")
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request

  config.before(type: :request) do |example|
    sign_in_as(create(:user)) unless example.metadata[:signed_out]
  end
end
