Rails.application.routes.draw do
  root to: "home#index"
  post 'chat', to: 'home#chat'
  post 'new_conversation', to: 'home#new_conversation'
  get "up" => "rails/health#show", as: :rails_health_check
end
