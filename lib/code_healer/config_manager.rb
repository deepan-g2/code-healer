require 'yaml'
require 'erb'

module CodeHealer
  class ConfigManager
    class << self
      def config
        @config ||= load_config
      end

      def reload_config
        @config = load_config
      end

      def enabled?
        config['enabled'] == true
      end

      def require_approval?
        config['require_approval'] == true
      end

      def auto_create_pr?
        # Use only the nested pull_request configuration for consistency
        config.dig('pull_request', 'auto_create') == true ||
        config.dig('pull_request', 'enabled') == true
      end

      def auto_generate_tests?
        config['auto_generate_tests'] == true
      end

      def allowed_error_types
        config['allowed_error_types'] || []
      end

      def allowed_classes
        config['allowed_classes'] || []
      end

      def excluded_classes
        config['excluded_classes'] || []
      end

      def can_evolve_class?(class_name)
        return false unless enabled?
        return false if excluded_classes.include?(class_name)
        return true if allowed_classes.empty?
        allowed_classes.include?(class_name)
      end

      def can_handle_error?(error)
        return false unless enabled?
        allowed_error_types.include?(error.class.name)
      end

      # Evolution Strategy Configuration
      def evolution_strategy
        config['evolution_strategy'] || {}
      end

      def evolution_method
        evolution_strategy['method'] || 'api'
      end

      def claude_code_enabled?
        evolution_method == 'claude_code_terminal' && 
        config.dig('claude_code', 'enabled') == true
      end

      def api_enabled?
        evolution_method == 'api' || 
        (evolution_method == 'hybrid' && config.dig('api', 'enabled') != false)
      end

      def fallback_to_api?
        evolution_strategy['fallback_to_api'] == true
      end

      # Claude Code Configuration
      def claude_code_settings
        config['claude_code'] || {}
      end

      def claude_persist_session?
        claude_code_settings['persist_session'] == true
      end

      def claude_preload_paths
        claude_code_settings['preload_paths'] || [
          'app', 'lib', 'config', 'Gemfile', 'Gemfile.lock'
        ]
      end

      def claude_ignore_paths
        claude_code_settings['ignore'] || [
          '.git', 'tmp', 'log', 'storage', 'node_modules', 'vendor', 'public', 'packs', '.bundle', 'bootsnap', 'cache'
        ]
      end

      # Business Context Configuration
      def business_context_enabled?
        config.dig('business_context', 'enabled') == true
      end

      def business_context_settings
        config['business_context'] || {}
      end

      # Business Context Strategy Configuration
      def business_context_strategy
        business_context_settings['strategy'] || 'markdown'
      end

      def use_jira_mcp?
        business_context_strategy == 'jira_mcp' || business_context_strategy == 'hybrid'
      end

      def use_markdown_context?
        business_context_strategy == 'markdown' || business_context_strategy == 'hybrid'
      end

      def use_hybrid_context?
        business_context_strategy == 'hybrid'
      end

      def jira_mcp_settings
        business_context_settings['jira_mcp'] || {}
      end

      def markdown_settings
        business_context_settings['markdown'] || {}
      end

      def hybrid_settings
        business_context_settings['hybrid'] || {}
      end

      def jira_mcp_enabled?
        use_jira_mcp? && jira_mcp_settings['enabled'] != false
      end

      def markdown_enabled?
        use_markdown_context? && markdown_settings['enabled'] != false
      end

      def jira_mcp_system_prompt
        jira_mcp_settings['system_prompt'] || default_jira_mcp_prompt
      end

      def default_jira_mcp_prompt
        <<~PROMPT
          When fixing code, ALWAYS check Jira MCP for business context:
          1. Search for tickets about the class/method you're fixing
          2. Use Jira requirements to ensure your fix follows business rules
          3. Reference specific Jira tickets in your explanation
          4. Make sure fixes align with business requirements
        PROMPT
      end

      # API Configuration
      def api_settings
        config['api'] || {}
      end

      # Demo Configuration
      def demo_settings
        config['demo'] || {}
      end

      def demo_mode?
        demo_settings['enabled'] == true
      end

      def demo_skip_tests?
        demo_mode? && demo_settings['skip_tests'] != false
      end



      def git_settings
        config['git'] || {}
      end
      
      # Code Heal Directory Configuration
      def code_heal_directory_config
        config['code_heal_directory'] || {}
      end
      
      def code_heal_directory_path
        code_heal_directory_config['path'] || '/tmp/code_healer_workspaces'
      end

      def sticky_workspace?
        cfg = code_heal_directory_config
        cfg['sticky_workspace'] == true || cfg[:sticky_workspace] == true
      end

      def persistent_workspaces_enabled?
        code_heal_directory_config['persistent_workspaces'] != false
      end
      
      def auto_cleanup_workspaces?
        code_heal_directory_config['auto_cleanup'] != false
      end
      
      def workspace_cleanup_after_hours
        code_heal_directory_config['cleanup_after_hours'] || 24
      end
      
      def max_workspaces
        code_heal_directory_config['max_workspaces'] || 10
      end

      def pull_request_settings
        config['pull_request'] || {}
      end

      def notification_settings
        config['notifications'] || {}
      end

      def safety_settings
        config['safety'] || {}
      end

      def evolution_patterns
        config['evolution_patterns'] || {}
      end

      def get_evolution_pattern(error_type)
        evolution_patterns[error_type.to_s]
      end

      def max_evolutions_per_day
        config['max_evolutions_per_day'] || 10
      end

      # Enhanced Git Configuration Methods
      def branch_prefix
        git_settings['branch_prefix'] || 'evolve'
      end

      def pr_target_branch
        # Check both git section and root level for backward compatibility
        git_settings['pr_target_branch'] || config['pr_target_branch'] || 'main'
      end

      def commit_message_template
        git_settings['commit_message_template'] || 'Fix {class_name}##{method_name}: {error_type}'
      end

      def auto_commit?
        git_settings['auto_commit'] != false
      end

      def auto_push?
        git_settings['auto_push'] != false
      end

      # Enhanced Safety Configuration Methods
      def backup_before_evolution?
        safety_settings['backup_before_evolution'] != false
      end

      def rollback_on_syntax_error?
        safety_settings['rollback_on_syntax_error'] != false
      end

      # Enhanced Pull Request Configuration Methods
      def pull_request_enabled?
        pull_request_settings['enabled'] != false
      end

      def auto_create_pr?
        pull_request_settings['auto_create'] == true
      end

      def pr_labels
        pull_request_settings['labels'] || ['auto-fix', 'self-evolving', 'bug-fix']
      end

      # Enhanced Claude Code Configuration Methods
      def claude_code_timeout
        claude_code_settings['timeout'] || 300
      end

      def claude_code_max_file_changes
        claude_code_settings['max_file_changes'] || 10
      end

      def claude_code_include_tests?
        claude_code_settings['include_tests'] != false
      end

      def claude_code_command_template
        claude_code_settings['command_template'] || "claude --print '{prompt}' --output-format text"
      end

      private

      def load_config
        # Try to find config file in current directory or parent directories
        config_path = find_config_file
        
        if config_path && File.exist?(config_path)
          YAML.load(ERB.new(File.read(config_path)).result)
        else
          default_config
        end
      rescue => e
        puts "Failed to load code-healer config: #{e.message}" if defined?(Rails)
        default_config
      end
      
      def find_config_file
        # Look for config file in current directory and parent directories
        current_dir = Dir.pwd
        max_depth = 5
        
        max_depth.times do |depth|
          config_path = File.join(current_dir, 'config', 'code_healer.yml')
          return config_path if File.exist?(config_path)
          
          # Go up one directory
          current_dir = File.dirname(current_dir)
          break if current_dir == '/'
        end
        
        nil
      end

      def default_config
        {
          'enabled' => true,
          'require_approval' => false,
          'max_evolutions_per_day' => 10,
          'auto_generate_tests' => true,
          'allowed_error_types' => ['ZeroDivisionError', 'NoMethodError', 'ArgumentError', 'TypeError'],
          'allowed_classes' => ['User', 'Order', 'PaymentProcessor'],
          'excluded_classes' => ['ApplicationController', 'ApplicationRecord', 'ApplicationJob', 'ApplicationMailer'],
          'evolution_strategy' => {
            'method' => 'api',
            'fallback_to_api' => true
          },
          'claude_code' => {
            'enabled' => false,
            'timeout' => 300,
            'max_file_changes' => 10,
            'include_tests' => true,
            'command_template' => "claude --print '{prompt}' --output-format text --permission-mode acceptEdits --allowedTools Edit",
            'business_context_sources' => [
              'config/business_rules.yml',
              'docs/business_logic.md',
              'spec/business_context_specs.rb'
            ]
          },
          'business_context' => {
            'enabled' => true,
            'sources' => ['docs/business_rules.md']
          },
          'api' => {
            'provider' => 'openai',
            'model' => 'gpt-4',
            'max_tokens' => 2000,
            'temperature' => 0.1
          },
          'demo' => {
            'enabled' => false,
            'skip_tests' => true
          },
          'git' => {
            'auto_commit' => true,
            'auto_push' => true,
            'branch_prefix' => 'evolve',
            'commit_message_template' => 'Fix {class_name}##{method_name}: {error_type}',
            'pr_target_branch' => 'main'
          },
          'pull_request' => {
            'enabled' => true,
            'auto_create' => true,
            'labels' => ['auto-fix', 'self-evolving', 'bug-fix']
          },
          'safety' => {
            'backup_before_evolution' => true,
            'rollback_on_syntax_error' => true
          },
          'code_heal_directory' => {
            'path' => '/tmp/code_healer_workspaces',
            'auto_cleanup' => true,
            'cleanup_after_hours' => 24,
            'max_workspaces' => 10,
            'clone_strategy' => 'branch',
            'persistent_workspaces' => true,
            'sticky_workspace' => false
          }
        }
      end
    end
  end
end 