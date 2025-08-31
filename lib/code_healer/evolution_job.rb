class EvolutionJob
  include Sidekiq::Job
  
  sidekiq_options retry: 3, backtrace: true, queue: 'evolution'
  
  def perform(error_data, class_name, method_name, file_path)
    puts "🚀 Evolution Job Started: #{class_name}##{method_name}"
    
    # Reconstruct the error object
    error = reconstruct_error(error_data)
    
    # Create isolated healing workspace
    workspace_path = create_healing_workspace(class_name, method_name)
    
    begin
      # Apply fixes in isolated environment
      success = apply_fixes_in_workspace(workspace_path, error, class_name, method_name)
      
      if success
        # Test fixes in isolated environment
        test_success = CodeHealer::HealingWorkspaceManager.test_fixes_in_workspace(workspace_path)
        
        if test_success
          # Merge back to main repo
          healing_branch = CodeHealer::HealingWorkspaceManager.create_healing_branch(
            Rails.root.to_s, 
            workspace_path, 
            CodeHealer::ConfigManager.pr_target_branch
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
  
  def apply_fixes_in_workspace(workspace_path, error, class_name, method_name)
    puts "🔧 Applying fixes in isolated workspace"
    
    # Determine evolution strategy
    evolution_method = CodeHealer::ConfigManager.evolution_method
    
    case evolution_method
    when 'claude_code_terminal'
      handle_claude_code_evolution_in_workspace(workspace_path, error, class_name, method_name)
    when 'api'
      handle_api_evolution_in_workspace(workspace_path, error, class_name, method_name)
    when 'hybrid'
      handle_hybrid_evolution_in_workspace(workspace_path, error, class_name, method_name)
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
  
  def handle_hybrid_evolution_in_workspace(workspace_path, error, class_name, method_name)
    puts "🔄 Using Hybrid approach for evolution in workspace..."
    
    begin
      # Try Claude Code first
      success = handle_claude_code_evolution_in_workspace(workspace_path, error, class_name, method_name)
      return success if success
    rescue => e
      puts "⚠️  Claude Code failed, falling back to API: #{e.message}"
    end
    
    # Fallback to API
    handle_api_evolution_in_workspace(workspace_path, error, class_name, method_name)
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
