Rails.application.routes.draw do
  get 'tags/:tag', to: 'articles#index', as: :tag
  
  resources :articles
  
  root 'articles#index'
end
