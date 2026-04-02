Rails.application.routes.draw do
  root to: "home#index"
  post 'chat', to: 'home#chat'
  get "up" => "rails/health#show", as: :rails_health_check
end
