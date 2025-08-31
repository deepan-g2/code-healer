require 'sidekiq'
require 'open3'

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

      # Track start metric
      healing_id = MetricsCollector.generate_healing_id
      MetricsCollector.track_healing_start(
        healing_id,
        class_name.to_s,
        method_name.to_s,
        error.class.name,
        error.message,
        nil # file_path not available in this flow
      )
      MetricsCollector.track_error_occurrence(healing_id, Time.current)

      puts "🚀 Evolution Job Started: #{class_name}##{method_name}"

      puts "🏥 [HEALING_JOB] About to create isolated healing workspace..."
      # Create isolated healing workspace
      workspace_path = create_healing_workspace(class_name, method_name)
      MetricsCollector.track_workspace_creation(healing_id, workspace_path)
      puts "🏥 [HEALING_JOB] Workspace created: #{workspace_path}"
      
      ai_time_ms = nil
      git_time_ms = nil
      test_success = false
      overall_success = false
      syntax_valid = false
      failure_reason = nil

      begin
        puts "🔧 [HEALING_JOB] About to apply fixes in isolated environment..."
        # Apply fixes in isolated environment
        ai_started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        success = apply_fixes_in_workspace(workspace_path, error, class_name, method_name, evolution_method)
        ai_time_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - ai_started_at) * 1000).round

        if success
          # Record AI processing success
          MetricsCollector.track_ai_processing(
            healing_id,
            evolution_method,
            ai_provider_for(evolution_method),
            'success'
          )

          # Test fixes in isolated environment
          test_success = CodeHealer::HealingWorkspaceManager.test_fixes_in_workspace(workspace_path)

          if test_success
            syntax_valid = true
            # Create healing branch from workspace
            git_started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            healing_branch = CodeHealer::HealingWorkspaceManager.create_healing_branch(
              Rails.root.to_s,
              workspace_path,
              CodeHealer::ConfigManager.pr_target_branch
            )
            git_time_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - git_started_at) * 1000).round

            if healing_branch
              MetricsCollector.track_git_operations(
                healing_id,
                healing_branch,
                nil,    # PR URL (skipped in workspace flow)
                false   # pr_created
              )
              overall_success = true
              puts "✅ Fixes applied, tested, and merged successfully! Branch: #{healing_branch}"
            else
              overall_success = false
              failure_reason ||= 'healing_branch_creation_failed'
              puts "⚠️  Fixes applied and tested, but merge failed"
            end
          else
            overall_success = false
            syntax_valid = false
            failure_reason ||= 'workspace_tests_failed_or_syntax_error'
            puts "⚠️  Fixes applied but failed tests, not merging back"
          end
        else
          overall_success = false
          failure_reason ||= 'ai_evolution_failed'
          # Record AI processing failure
          MetricsCollector.track_ai_failure(
            healing_id,
            evolution_method,
            ai_provider_for(evolution_method),
            failure_reason
          )
          puts "❌ Failed to apply fixes in workspace"
        end
      ensure
        # Persist timing metrics if captured
        MetricsCollector.track_timing(healing_id, ai_time_ms, git_time_ms) if ai_time_ms || git_time_ms
        # Mark completion
        MetricsCollector.track_healing_completion(
          healing_id,
          overall_success,
          test_success,
          syntax_valid,
          failure_reason
        )
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
    
    def log_mcp_tools_availability
      puts "🔍 [HEALING_JOB] Checking MCP tools availability..."
      
      begin
        # Check if Claude has MCP tools available
        mcp_check_command = "claude --print 'List all available MCP tools' --output-format text"
        stdout, stderr, status = Open3.capture3(mcp_check_command)
        
        if status.success?
          puts "✅ [HEALING_JOB] Claude Terminal is available"
          
          # Extract MCP tools from output
          if stdout.include?("MCP tools available") || stdout.include?("mcp__")
            puts "🔧 [HEALING_JOB] MCP tools detected in Claude Terminal"
            
            # Log specific MCP tools if found
            if stdout.include?("mcp__atlassian")
              puts "   - Atlassian MCP tools: Available"
              puts "   - Jira integration: Available"
              puts "   - Confluence integration: Available"
            end
            
            if stdout.include?("mcp__")
              puts "   - Other MCP tools: Available"
            end
          else
            puts "⚠️  [HEALING_JOB] No MCP tools detected in Claude Terminal"
            puts "💡 Make sure Claude Terminal has MCP tools configured"
          end
        else
          puts "❌ [HEALING_JOB] Claude Terminal is not available"
          puts "💡 Make sure Claude Terminal is installed and accessible"
        end
      rescue => e
        puts "⚠️  [HEALING_JOB] Could not check MCP tools: #{e.message}"
        puts "💡 Make sure Claude Terminal is properly installed"
      end
      
      puts "🔍 [HEALING_JOB] MCP tools check complete"
    end

    def extract_file_path_from_error(error)
      return nil unless error&.backtrace
      
      # Look for the first line that contains a file path
      error.backtrace.each do |line|
        if line.match?(/^(.+\.rb):\d+:in/)
          file_path = $1
          # Convert to absolute path if it's relative
          if file_path.start_with?('./') || !file_path.start_with?('/')
            file_path = File.expand_path(file_path)
          end
          return file_path
        end
      end
      
      nil
    end
    
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

    def ai_provider_for(evolution_method)
      case evolution_method
      when 'claude_code_terminal'
        'claude'
      when 'api'
        'openai'
      when 'hybrid'
        'hybrid'
      else
        'unknown'
      end
    end

    def create_healing_workspace(class_name, method_name)
      puts "🏥 Creating isolated healing workspace for #{class_name}##{method_name}"

      # Create persistent workspace and checkout to target branch
      workspace_path = CodeHealer::HealingWorkspaceManager.create_healing_workspace(
        Rails.root.to_s,
        CodeHealer::ConfigManager.pr_target_branch  # Use configured target branch
      )

      puts "✅ Healing workspace ready: #{workspace_path}"
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

      # Optionally record business context used
      # MetricsCollector.track_business_context(healing_id, business_context) # healing_id not accessible here

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
