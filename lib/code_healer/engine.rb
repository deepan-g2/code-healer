module CodeHealer
  class Engine < ::Rails::Engine
    isolate_namespace CodeHealer
    
    # Automatically mount the engine
    initializer "code_healer.mount_engine" do |app|
      app.routes.prepend do
        mount CodeHealer::Engine => "/code_healer"
      end
    end
    
    # Load dashboard components
    initializer "code_healer.load_dashboard" do |app|
      app.config.autoload_paths += %W(#{config.root}/lib/code_healer)
    end
    
    # Copy migrations
    initializer "code_healer.copy_migrations" do |app|
      if app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
    
    # Add dashboard routes
    initializer "code_healer.add_routes" do |app|
      app.routes.prepend do
        namespace :code_healer do
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
    end
  end
end
