Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  
  #sget'/dev', to: 'dev#dev'

  root 'sessions#new'
  resource :sessions, only: [:new, :create]
  resource :invoices, only: [:new, :create]
  resources :reports, only: [:show]

end
