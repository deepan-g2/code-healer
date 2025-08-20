module CodeHealer
  class Installer
    def self.install_dashboard
      puts "🏥 CodeHealer Dashboard Installation"
      puts "=================================="
      
      # Check if we're in a Rails app
      unless defined?(Rails)
        puts "❌ This command must be run from within a Rails application"
        return false
      end
      
      # Check if dashboard is already installed
      if dashboard_installed?
        puts "✅ Dashboard is already installed!"
        puts "🌐 Access it at: /code_healer/dashboard"
        return true
      end
      
      puts "🚀 Installing CodeHealer Dashboard..."
      
      # The engine will automatically handle:
      # - Routes mounting
      # - Migration copying
      # - Asset loading
      
      puts "✅ Dashboard installation completed!"
      puts "🚀 Run 'rails db:migrate' to create the database tables"
      puts "🌐 Access your dashboard at: /code_healer/dashboard"
      puts ""
      puts "📊 Dashboard Features:"
      puts "   - Real-time healing metrics"
      puts "   - AI performance analytics"
      puts "   - Success rate tracking"
      puts "   - Interactive charts and graphs"
      
      true
    end
    
    private
    
    def self.dashboard_installed?
      # Check if the routes are already mounted
      Rails.application.routes.routes.any? do |route|
        route.path.spec.to_s.include?('code_healer')
      end
    rescue
      false
    end
  end
end
