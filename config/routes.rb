Rails.application.routes.draw do
  # get 'users/index'
  #
  # get 'users/show'
  #
  # get 'users/new'
  #
  # get 'users/create'
  #
  # get 'users/edit'
  #
  # get 'users/update'
  #
  # get 'users/destroy'

  devise_for :users, path: 'auth', skip: [:registrations]

  resources :users do
    get 'reinvite', on: :member 
  end

  resources :regimes do
    resources :permits
    resources :permit_categories
    resources :transactions, only: [:index, :show, :edit, :update]
    resources :history, only: [:index, :show]
    resources :transaction_files, except: [:new, :destroy]
    resources :transaction_summary, only: [:index]
    resources :annual_billing_data_files, except: [:destroy]
  end

  root to: 'transactions#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # TODO: protect me when we add users
  require 'resque/server'
  mount Resque::Server, at: '/jobs'
end
