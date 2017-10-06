class HomeController < ApplicationController
  before_filter :authenticate_api_user!
end
