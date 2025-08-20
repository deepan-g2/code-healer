require 'sidekiq'

module CodeHealer
  class HealingJob
    include Sidekiq::Job

    sidekiq_options retry: 3, backtrace: true, queue: 'evolution'

    def perform(*args)
      puts "🚀 [HEALING_JOB] Starting job with args: #{args.inspect}"
      
      # Support both legacy and new invocation styles
      error, class_name, method_name, evolution_method, backtrace = parse_args(args)
      
      puts "🚀 [HEALING_JOB] Parsed args - Error: #{error.class}, Class: #{class_name}, Method: #{method_name}, Evolution: #{evolution_method}"
      puts "🚀 [HEALING_JOB] Backtrace length: #{backtrace&.length || 0}"

      puts "🚀 Evolution Job Started: #{class_name}##{method_name}"

            puts "🏥 [HEALING_JOB] About to create isolated healing workspace..."
      # Create isolated healing workspace
      workspace_path = create_healing_workspace(class_name, method_name)
      puts "🏥 [HEALING_JOB] Workspace created: #{workspace_path}"
      
      begin
        puts "🔧 [HEALING_JOB] About to apply fixes in isolated environment..."
        # Apply fixes in isolated environment
        success = apply_fixes_in_workspace(workspace_path, error, class_name, method_name, evolution_method)

        if success
          # Test fixes in isolated environment
          test_success = CodeHealer::HealingWorkspaceManager.test_fixes_in_workspace(workspace_path)

          if test_success
            # Merge back to main repo
            healing_branch = CodeHealer::HealingWorkspaceManager.create_healing_branch(
              Rails.root.to_s,
              workspace_path,
              CodeHealer::ConfigManager.git_settings['pr_target_branch'] || 'main'
            )

            if healing_branch
              puts "✅ Fixes applied, tested, and merged successfully! Branch: #{healing_branch}"
            else
              puts "⚠️  Fixes applied and tested, but merge failed"
            end
          else
            puts "⚠️  Fixes applied but failed tests, not merging back"
          end
        else
          puts "❌ Failed to apply fixes in workspace"
        end
      ensure
        # Clean up workspace
        cleanup_workspace(workspace_path)
      end

      puts "✅ Evolution Job Completed: #{class_name}##{method_name}"
    rescue => e
      puts "❌ Evolution Job Failed: #{e.message}"
      puts "📍 Backtrace: #{e.backtrace.first(5)}"
      raise e  # Re-raise to trigger Sidekiq retry
    end

    private

    def parse_args(args)
      # Formats supported:
      # 1) [error_class, error_message, class_name, method_name, evolution_method, backtrace]
      # 2) [error_data_hash, class_name, method_name, file_path]
      if args.length >= 6 && args[0].is_a?(String)
        error_class, error_message, class_name, method_name, evolution_method, backtrace = args
        error = reconstruct_error({ 'class' => error_class, 'message' => error_message, 'backtrace' => backtrace })
        [error, class_name, method_name, evolution_method, backtrace]
      elsif args.length == 4 && args[0].is_a?(Hash)
        error_data, class_name, method_name, _file_path = args
        error = reconstruct_error(error_data)
        evolution_method = CodeHealer::ConfigManager.evolution_method
        [error, class_name, method_name, evolution_method, error.backtrace]
      else
        raise ArgumentError, "Unsupported HealingJob arguments: #{args.inspect}"
      end
    end

    def create_healing_workspace(class_name, method_name)
      puts "🏥 Creating isolated healing workspace for #{class_name}##{method_name}"

      # Create unique workspace
      workspace_path = CodeHealer::HealingWorkspaceManager.create_healing_workspace(
        Rails.root.to_s,
        nil  # Use current branch
      )

      puts "✅ Healing workspace created: #{workspace_path}"
      workspace_path
    end

    def apply_fixes_in_workspace(workspace_path, error, class_name, method_name, evolution_method)
      puts "🔧 Applying fixes in isolated workspace"

      case evolution_method
      when 'claude_code_terminal'
        handle_claude_code_evolution_in_workspace(workspace_path, error, class_name, method_name)
      when 'api'
        handle_api_evolution_in_workspace(workspace_path, error, class_name, method_name)
      when 'hybrid'
        begin
          success = handle_claude_code_evolution_in_workspace(workspace_path, error, class_name, method_name)
          return true if success
        rescue => e
          puts "⚠️  Claude Code failed, falling back to API: #{e.message}"
        end
        handle_api_evolution_in_workspace(workspace_path, error, class_name, method_name)
      else
        puts "❌ Unknown evolution method: #{evolution_method}"
        false
      end
    end

    def handle_claude_code_evolution_in_workspace(workspace_path, error, class_name, method_name)
      puts "🤖 Using Claude Code Terminal for evolution in workspace..."

      # Change to workspace directory for Claude Code operations
      Dir.chdir(workspace_path) do
        success = CodeHealer::ClaudeCodeEvolutionHandler.handle_error_with_claude_code(
          error, class_name, method_name, nil  # file_path not needed in workspace
        )

        if success
          puts "✅ Claude Code evolution completed successfully in workspace!"
          true
        else
          puts "❌ Claude Code evolution failed in workspace"
          false
        end
      end
    end

    def handle_api_evolution_in_workspace(workspace_path, error, class_name, method_name)
      puts "🌐 Using OpenAI API for evolution in workspace..."

      # Load business context for API evolution
      business_context = CodeHealer::BusinessContextManager.get_context_for_error(
        error, class_name, method_name
      )

      puts "📋 Business context loaded for API evolution"

      # Change to workspace directory for API operations
      Dir.chdir(workspace_path) do
        success = CodeHealer::SimpleEvolution.handle_error_with_mcp_intelligence(
          error, class_name, method_name, nil, business_context  # file_path not needed in workspace
        )

        if success
          puts "✅ API evolution completed successfully in workspace!"
          true
        else
          puts "❌ API evolution failed in workspace"
          false
        end
      end
    end

    def cleanup_workspace(workspace_path)
      return unless workspace_path && Dir.exist?(workspace_path)

      puts "🧹 Cleaning up healing workspace: #{workspace_path}"
      CodeHealer::HealingWorkspaceManager.cleanup_workspace(workspace_path)
    end

    def reconstruct_error(error_data)
      # Reconstruct the error object from serialized data
      error_class = Object.const_get(error_data['class'])
      error = error_class.new(error_data['message'])

      # Restore backtrace if available
      if error_data['backtrace']
        error.set_backtrace(error_data['backtrace'])
      end

      error
    end
  end
end

# This duplicate class has been removed to fix the isolated healing workspace system
