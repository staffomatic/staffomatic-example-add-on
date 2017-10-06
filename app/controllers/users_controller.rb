class UsersController < ApplicationController

  before_filter :authenticate_api_user!

  def index
    @users = staffomatic_client.all_users
  end

end
