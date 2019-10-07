Rails.application.routes.draw do

  root 'static_pages#home'
  get 'static_pages/about'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'
  resources :users do
    member do
      get :following, :followers, :bookmark
    end
  end
  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  resources :novels
  resources :stories do
    member do
      get :impression
    end
  end
  resources :pictures
  resources :impressions
  resources :messages,only: [:create]
  resources :rooms,only: [:show,:create]
  resources :bookmarks, only: [:create, :destroy]
  resources :relationships, only: [:create, :destroy]
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
