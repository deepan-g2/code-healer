CodeHealer::Engine.routes.draw do
  get '/dashboard', to: 'dashboard#index'
  get '/dashboard/metrics', to: 'dashboard#metrics'
  get '/dashboard/trends', to: 'dashboard#trends'
  get '/dashboard/performance', to: 'dashboard#performance'
  get '/dashboard/healing/:healing_id', to: 'dashboard#healing_details'
  
  # API endpoints (JSON only) - default to JSON format
  scope path: '/api', defaults: { format: :json } do
    get '/dashboard/summary', to: 'dashboard#summary'
    get '/dashboard/metrics', to: 'dashboard#metrics'
    get '/dashboard/trends', to: 'dashboard#trends'
    get '/dashboard/performance', to: 'dashboard#performance'
    get '/dashboard/healing/:healing_id', to: 'dashboard#healing_details'
  end
end
