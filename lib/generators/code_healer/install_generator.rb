module CodeHealer
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      
      desc "Installs CodeHealer dashboard and required components"
      
      def install_dashboard
        # Generate migration
        generate_migration
        
        # Add routes
        inject_routes
        
        # Create initializer
        create_initializer
        
        # Copy dashboard assets
        copy_dashboard_assets
        
        puts "✅ CodeHealer dashboard installed successfully!"
        puts "🚀 Run 'rails db:migrate' to create the database tables"
        puts "🌐 Access your dashboard at: /code_healer/dashboard"
      end
      
      private
      
      def generate_migration
        migration_template "create_healing_metrics.rb", "db/migrate/create_healing_metrics.rb"
      end
      
      def inject_routes
        route "mount CodeHealer::Engine => '/code_healer'"
      end
      
      def create_initializer
        copy_file "code_healer.rb", "config/initializers/code_healer.rb"
      end
      
      def copy_dashboard_assets
        copy_file "dashboard_controller.rb", "app/controllers/code_healer/dashboard_controller.rb"
        copy_file "healing_metric.rb", "app/models/code_healer/healing_metric.rb"
        copy_file "metrics_collector.rb", "app/services/code_healer/metrics_collector.rb"
        copy_file "dashboard_index.html.erb", "app/views/code_healer/dashboard/index.html.erb"
      end
    end
  end
end
