module CodeHealer
  class Engine < ::Rails::Engine
    isolate_namespace CodeHealer
    
    # Load dashboard components
    initializer "code_healer.load_dashboard" do |app|
      app.config.autoload_paths += %W(#{config.root}/lib/code_healer)
    end
    
    # Add views path to the main app
    initializer "code_healer.add_views_path" do |app|
      app.config.paths["app/views"] << "#{config.root}/lib/code_healer/views"
    end
    
    # Copy migrations
    initializer "code_healer.copy_migrations" do |app|
      if app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
    
    # Ensure the engine is properly loaded
    config.autoload_paths += %W(#{config.root}/lib)
    config.eager_load_paths += %W(#{config.root}/lib)
    
    # Configure the engine's own paths
    config.paths["app/views"] = ["#{config.root}/lib/code_healer/views"]
  end
end
