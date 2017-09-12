Rails.application.routes.draw do
  resources :regimes do
    resources :permits
  end

  root to: 'regimes#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
