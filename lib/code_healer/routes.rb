# CodeHealer Dashboard Routes
Rails.application.routes.draw do
  namespace :code_healer do
    # Dashboard
    get '/dashboard', to: 'dashboard#index'
    get '/dashboard/metrics', to: 'dashboard#metrics'
    get '/dashboard/trends', to: 'dashboard#trends'
    get '/dashboard/performance', to: 'dashboard#performance'
    get '/dashboard/healing/:healing_id', to: 'dashboard#healing_details'
    
    # API endpoints (JSON only)
    namespace :api do
      get '/dashboard/summary', to: 'dashboard#summary'
      get '/dashboard/metrics', to: 'dashboard#metrics'
      get '/dashboard/trends', to: 'dashboard#trends'
      get '/dashboard/performance', to: 'dashboard#performance'
      get '/dashboard/healing/:healing_id', to: 'dashboard#healing_details'
    end
  end
end
