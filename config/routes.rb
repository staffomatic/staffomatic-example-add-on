Rails.application.routes.draw do
	root to: "home#show"

  controller :sessions do
    get 'login' => :new
    get 'auth/staffomatic/callback' => :show
  end
end
