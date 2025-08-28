# frozen_string_literal: true

require_relative "code_healer/version"
require_relative "code_healer/engine"

# Require external gems explicitly
require 'openai'
require 'sidekiq'
require 'git'
require 'octokit'
require 'open3'

# CodeHealer - AI-Powered Code Healing and Self-Repair System
module CodeHealer
  class Error < StandardError; end
  

end

# Autoload all the main classes
autoload :ConfigManager, "code_healer/config_manager"
autoload :BusinessContextManager, "code_healer/business_context_manager"
autoload :ClaudeCodeEvolutionHandler, "code_healer/claude_code_evolution_handler"
autoload :SimpleHealer, "code_healer/simple_healer"
autoload :HealingJob, "code_healer/healing_job"
autoload :HealingWorkspaceManager, "code_healer/healing_workspace_manager"
autoload :PullRequestCreator, "code_healer/pull_request_creator"
autoload :McpServer, "code_healer/mcp_server"
autoload :McpTools, "code_healer/mcp_tools"
autoload :McpPrompts, "code_healer/mcp_prompts"
autoload :MCP, "code_healer/mcp"

# Dashboard components - load them explicitly to avoid autoload issues
require_relative "code_healer/models/healing_metric"
require_relative "code_healer/services/metrics_collector"
require_relative "code_healer/controllers/dashboard_controller"
require_relative "code_healer/claude_session"
autoload :Installer, "code_healer/installer"

# Rails integration
if defined?(Rails)
  require "rails"
  
  # Railtie for automatic Rails integration
  class CodeHealerRailtie < Rails::Railtie
    initializer "code_healer.configure" do |app|
      # Load configuration
      config_path = Rails.root.join("config", "code_healer.yml")
      
      if File.exist?(config_path)
        puts "🏥 CodeHealer: Loading configuration from #{config_path}"
        
        # Load all the main classes
        Dir[File.join(__dir__, "code_healer", "*.rb")].each do |file|
          # Skip the setup script as it's only for the executable
          next if file.include?("setup.rb")
          
          require file
        end
        
        # Initialize Core and set up error handling
        if defined?(CodeHealer::Core)
          config = YAML.load_file(config_path)
          CodeHealer::Core.initialize(config)
          CodeHealer::Core.setup_error_handling
        end
        
        puts "🏥 CodeHealer: Initialized successfully!"
        puts "   Configuration loaded from: #{config_path}"
        puts "   Run 'code_healer-setup' to reconfigure if needed"
      else
        puts "🏥 CodeHealer: No configuration file found at #{config_path}"
        puts "   Run 'code_healer-setup' to configure CodeHealer"
      end
    end
    
    # Mount the engine to provide dashboard routes and views
    initializer "code_healer.mount_engine" do |app|
      app.routes.prepend do
        mount CodeHealer::Engine => "/code_healer"
      end
    end

    # Preload Claude session and repository context once per boot
    config.after_initialize do
      begin
        CodeHealer::ClaudeSession.start!
      rescue => e
        puts "⚠️ Claude preload failed: #{e.message}"
      end
    end
    

  end
end
