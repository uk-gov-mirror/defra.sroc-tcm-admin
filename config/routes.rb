Rails.application.routes.draw do
  devise_for :users, path: 'auth', skip: [:registrations]

  as :user do
    get 'change_password/edit' => 'devise/registrations#edit', as: 'edit_user_registration'
    patch 'change_password' => 'devise/registrations#update', as: 'user_registration'
  end

  resources :users do
    get 'reinvite', on: :member 
  end

  resources :regimes, only: [] do
    resources :permit_categories, only: [:index]
    resources :transactions, only: [:index, :show, :edit, :update]
    resources :history, only: [:index, :show]
    resources :retrospectives, only: [:index, :show]
    resources :transaction_files, only: [:create]
    resources :transaction_summary, only: [:index]
    resources :retrospective_files, only: [:create]
    resources :retrospective_summary, only: [:index]
    resources :annual_billing_data_files, except: [:destroy]
  end

  root to: 'transactions#index'

  # TODO: protect me when we add users
  require 'resque/server'
  authenticate(:user, ->(u) { u.admin? }) do
    mount Resque::Server, at: '/jobs'
  end

  match '(errors)/:status', to: 'errors#show', via: :all, constraints: { status: /\d{3}/ }
end
