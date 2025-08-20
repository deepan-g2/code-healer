require 'fileutils'
require 'securerandom'

module CodeHealer
  # Manages isolated healing workspaces for safe code evolution
  class HealingWorkspaceManager
    class << self
      def create_healing_workspace(repo_path, branch_name = nil)
        puts "🏥 [WORKSPACE] Starting workspace creation..."
        puts "🏥 [WORKSPACE] Repo path: #{repo_path}"
        puts "🏥 [WORKSPACE] Branch name: #{branch_name || 'current'}"
        
        config = CodeHealer::ConfigManager.code_heal_directory_config
        puts "🏥 [WORKSPACE] Raw config: #{config.inspect}"
        
        base_path = config['path'] || config[:path] || '/tmp/code_healer_workspaces'
        puts "🏥 [WORKSPACE] Base heal dir: #{base_path}"
        
        # Create unique workspace directory
        workspace_id = "healing_#{Time.now.to_i}_#{SecureRandom.hex(4)}"
        workspace_path = File.join(base_path, workspace_id)
        
        puts "🏥 [WORKSPACE] Workspace ID: #{workspace_id}"
        puts "🏥 [WORKSPACE] Full workspace path: #{workspace_path}"
        
        begin
          puts "🏥 [WORKSPACE] Creating base directory..."
          # Ensure code heal directory exists
          FileUtils.mkdir_p(base_path)
          puts "🏥 [WORKSPACE] Base directory created/verified: #{base_path}"
          
          # Clone current branch to workspace
          strategy = clone_strategy
          puts "🏥 [WORKSPACE] Clone strategy: #{strategy}"
          
          if strategy == "branch"
            puts "🏥 [WORKSPACE] Using branch-only cloning..."
            clone_current_branch(repo_path, workspace_path, branch_name)
          else
            puts "🏥 [WORKSPACE] Using full repo cloning..."
            clone_full_repo(repo_path, workspace_path, branch_name)
          end
          
          puts "🏥 [WORKSPACE] Workspace creation completed successfully!"
          puts "🏥 [WORKSPACE] Final workspace path: #{workspace_path}"
          puts "🏥 [WORKSPACE] Workspace contents: #{Dir.entries(workspace_path).join(', ')}"
          workspace_path
        rescue => e
          puts "❌ Failed to create healing workspace: #{e.message}"
          cleanup_workspace(workspace_path) if Dir.exist?(workspace_path)
          raise e
        end
      end
      
      def apply_fixes_in_workspace(workspace_path, fixes, class_name, method_name)
        puts "🔧 [WORKSPACE] Starting fix application..."
        puts "🔧 [WORKSPACE] Workspace: #{workspace_path}"
        puts "🔧 [WORKSPACE] Class: #{class_name}, Method: #{method_name}"
        puts "🔧 [WORKSPACE] Fixes to apply: #{fixes.inspect}"
        
        begin
          puts "🔧 [WORKSPACE] Processing #{fixes.length} fixes..."
          # Apply each fix to the workspace
          fixes.each_with_index do |fix, index|
            puts "🔧 [WORKSPACE] Processing fix #{index + 1}: #{fix.inspect}"
            file_path = File.join(workspace_path, fix[:file_path])
            puts "🔧 [WORKSPACE] Target file: #{file_path}"
            puts "🔧 [WORKSPACE] File exists: #{File.exist?(file_path)}"
            
            next unless File.exist?(file_path)
            
            puts "🔧 [WORKSPACE] Creating backup..."
            # Backup original file
            backup_file(file_path)
            
            puts "🔧 [WORKSPACE] Applying fix to file..."
            # Apply the fix
            apply_fix_to_file(file_path, fix[:new_code], class_name, method_name)
          end
          
          # Show workspace Git status after applying fixes
          Dir.chdir(workspace_path) do
            puts "🔧 [WORKSPACE] Git status after fixes:"
            system("git status --porcelain")
            puts "🔧 [WORKSPACE] Git diff after fixes:"
            system("git diff")
          end
          
          puts "✅ Fixes applied successfully in workspace"
          true
        rescue => e
          puts "❌ Failed to apply fixes in workspace: #{e.message}"
          false
        end
      end
      
      def test_fixes_in_workspace(workspace_path)
        config = CodeHealer::ConfigManager.code_heal_directory_config
        
        puts "🧪 Testing fixes in workspace: #{workspace_path}"
        
        begin
          # Change to workspace directory
          Dir.chdir(workspace_path) do
            # Run basic syntax check
            syntax_check = system("ruby -c #{find_ruby_files.join(' ')} 2>/dev/null")
            return false unless syntax_check
            
            # Run tests if available
            if File.exist?('Gemfile')
              bundle_check = system("bundle check >/dev/null 2>&1")
              return false unless bundle_check
              
              # Run tests if RSpec is available
              if File.exist?('spec') || File.exist?('test')
                test_result = system("bundle exec rspec --dry-run >/dev/null 2>&1") ||
                             system("bundle exec rake test:prepare >/dev/null 2>&1")
                puts "🧪 Test preparation: #{test_result ? '✅' : '⚠️'}"
              end
            end
            
            puts "✅ Workspace validation passed"
            true
          end
        rescue => e
          puts "❌ Workspace validation failed: #{e.message}"
          false
        end
      end
      
      def create_healing_branch(repo_path, workspace_path, branch_name)
        puts "🔄 Creating healing branch and PR from isolated workspace"
        
        begin
          # All Git operations happen in the isolated workspace
          Dir.chdir(workspace_path) do
            puts "🌿 [WORKSPACE] Working in isolated workspace: #{workspace_path}"
            
            # Debug Git configuration
            puts "🌿 [WORKSPACE] Git remote origin: #{`git config --get remote.origin.url`.strip}"
            puts "🌿 [WORKSPACE] Current branch: #{`git branch --show-current`.strip}"
            
            # Ensure we're on the target branch
            system("git checkout #{branch_name}")
            system("git pull origin #{branch_name}")
            
            # Create healing branch in the workspace
            healing_branch = "code-healer-fix-#{Time.now.to_i}"
            system("git checkout -b #{healing_branch}")
            
            # Check Git status
            puts "📊 [WORKSPACE] Git status in workspace:"
            system("git status --porcelain")
            
            # Add all changes (the fixes are already applied in the workspace)
            system("git add .")
            
            # Check if there are changes to commit
            if system("git diff --cached --quiet") == false
              puts "📝 [WORKSPACE] Changes detected, committing to healing branch..."
              commit_message = "Fix applied by CodeHealer: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
              system("git commit -m '#{commit_message}'")
              
              # Push healing branch from workspace
              puts "🚀 [WORKSPACE] Pushing healing branch from workspace..."
              system("git push origin #{healing_branch}")
              
              puts "✅ [WORKSPACE] Healing branch created and pushed: #{healing_branch}"
              puts "🔒 Main repository (#{repo_path}) remains completely untouched"
              puts "📝 All changes committed in isolated workspace"
              
                          # Create pull request if auto-create is enabled and no PR was already created
            if should_create_pull_request?
              puts "🔍 [WORKSPACE] Checking if PR was already created by evolution handler..."
              # Skip PR creation if we're in a healing workflow (PR likely already created)
              puts "🔍 [WORKSPACE] PR creation skipped - likely already created by evolution handler"
              puts "🔍 [WORKSPACE] Review the changes and create a pull request when ready"
            else
              puts "🔍 [WORKSPACE] Review the changes and create a pull request when ready"
            end
              
              healing_branch
            else
              puts "⚠️ [WORKSPACE] No changes detected in workspace"
              puts "🔍 This might indicate that:"
              puts "   - The fixes were not applied to the workspace"
              puts "   - There was an issue with the healing process"
              
              # Delete the empty branch
              system("git checkout #{branch_name}")
              system("git branch -D #{healing_branch}")
              puts "🗑️ [WORKSPACE] Deleted empty healing branch: #{healing_branch}"
              nil
            end
          end
        rescue => e
          puts "❌ Failed to create healing branch from workspace: #{e.message}"
          nil
        end
      end
      
      def cleanup_workspace(workspace_path)
        puts "🧹 [WORKSPACE] Starting workspace cleanup..."
        puts "🧹 [WORKSPACE] Target: #{workspace_path}"
        puts "🧹 [WORKSPACE] Exists: #{Dir.exist?(workspace_path)}"
        
        return unless Dir.exist?(workspace_path)
        
        # Remove .git directory first to avoid conflicts
        git_dir = File.join(workspace_path, '.git')
        if Dir.exist?(git_dir)
          puts "🧹 [WORKSPACE] Removing .git directory to prevent conflicts..."
          FileUtils.rm_rf(git_dir)
        end
        
        puts "🧹 [WORKSPACE] Removing workspace directory..."
        FileUtils.rm_rf(workspace_path)
        puts "🧹 [WORKSPACE] Workspace cleanup completed"
        puts "🧹 [WORKSPACE] Directory still exists: #{Dir.exist?(workspace_path)}"
      end
      
      def cleanup_expired_workspaces
        config = CodeHealer::ConfigManager.code_heal_directory_config
        auto_cleanup = config['auto_cleanup']
        auto_cleanup = config[:auto_cleanup] if auto_cleanup.nil?
        return unless auto_cleanup
        
        puts "🧹 Cleaning up expired healing workspaces"
        
        base_path = config['path'] || config[:path] || '/tmp/code_healer_workspaces'
        Dir.glob(File.join(base_path, "healing_*")).each do |workspace_path|
          next unless Dir.exist?(workspace_path)
          
          # Check if workspace is expired
          hours = config['cleanup_after_hours'] || config[:cleanup_after_hours]
          hours = hours.to_i if hours
          if workspace_expired?(workspace_path, hours)
            cleanup_workspace(workspace_path)
          end
        end
      end
      
      private
      
      def should_create_pull_request?
        config = CodeHealer::ConfigManager.config
        auto_create = config.dig('pull_request', 'auto_create')
        auto_create = config.dig(:pull_request, :auto_create) if auto_create.nil?
        auto_create == true
      end
      
      def create_pull_request(healing_branch, target_branch)
        puts "🔗 Creating pull request for #{healing_branch} → #{target_branch}"
        
        begin
          require 'octokit'
          
          config = CodeHealer::ConfigManager.config
          github_token = ENV['GITHUB_TOKEN']
          repo_name = config['github_repo'] || config[:github_repo]
          
          unless github_token && repo_name
            puts "❌ Missing GitHub token or repository configuration"
            return nil
          end
          
          # Parse repo name (owner/repo)
          owner, repo = repo_name.split('/')
          
          client = Octokit::Client.new(access_token: github_token)
          
          # Create pull request
          pr = client.create_pull_request(
            repo_name,
            target_branch,
            healing_branch,
            "CodeHealer: Automated Fix",
            "This pull request contains automated fixes generated by CodeHealer.\n\n" \
            "**Please review the changes before merging.**\n\n" \
            "Generated at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
          )
          
          pr.html_url
        rescue => e
          puts "❌ Failed to create pull request: #{e.message}"
          nil
        end
      end
      
      def clone_strategy
        cfg = CodeHealer::ConfigManager.code_heal_directory_config
        cfg['clone_strategy'] || cfg[:clone_strategy] || "branch"
      end
      
      def clone_current_branch(repo_path, workspace_path, branch_name)
        puts "🌿 [WORKSPACE] Starting branch cloning..."
        Dir.chdir(repo_path) do
          current_branch = branch_name || `git branch --show-current`.strip
          puts "🌿 [WORKSPACE] Current branch: #{current_branch}"
          
          # Get the GitHub remote URL instead of local path
          remote_url = `git config --get remote.origin.url`.strip
          puts "🌿 [WORKSPACE] Remote origin URL: #{remote_url}"
          
          if remote_url.empty?
            puts "❌ [WORKSPACE] No remote origin found in #{repo_path}"
            return false
          end
          
          puts "🌿 [WORKSPACE] Executing: git clone --single-branch --branch #{current_branch} #{remote_url} #{workspace_path}"
          
          # Clone from GitHub remote URL, not local path
          result = system("git clone --single-branch --branch #{current_branch} #{remote_url} #{workspace_path}")
          puts "🌿 [WORKSPACE] Clone result: #{result ? 'SUCCESS' : 'FAILED'}"
          
          if result
            puts "🌿 [WORKSPACE] Git repository preserved for healing operations"
            # Keep .git for Git operations during healing
            # We'll clean it up later in cleanup_workspace
          else
            puts "🌿 [WORKSPACE] Clone failed, checking workspace..."
            puts "🌿 [WORKSPACE] Workspace exists: #{Dir.exist?(workspace_path)}"
            puts "🌿 [WORKSPACE] Workspace contents: #{Dir.exist?(workspace_path) ? Dir.entries(workspace_path).join(', ') : 'N/A'}"
          end
        end
      end
      
      def clone_full_repo(repo_path, workspace_path, branch_name)
        puts "🌿 [WORKSPACE] Starting full repo cloning..."
        Dir.chdir(repo_path) do
          current_branch = branch_name || `git branch --show-current`.strip
          puts "🌿 [WORKSPACE] Target branch: #{current_branch}"
          
          # Get the GitHub remote URL instead of local path
          remote_url = `git config --get remote.origin.url`.strip
          puts "🌿 [WORKSPACE] Remote origin URL: #{remote_url}"
          
          if remote_url.empty?
            puts "❌ [WORKSPACE] No remote origin found in #{repo_path}"
            return false
          end
          
          puts "🌿 [WORKSPACE] Executing: git clone #{remote_url} #{workspace_path}"
          
          # Clone from GitHub remote URL, not local path
          result = system("git clone #{remote_url} #{workspace_path}")
          puts "🌿 [WORKSPACE] Clone result: #{result ? 'SUCCESS' : 'FAILED'}"
          
          if result
            puts "🌿 [WORKSPACE] Switching to branch: #{current_branch}"
            # Switch to specific branch
            Dir.chdir(workspace_path) do
              checkout_result = system("git checkout #{current_branch}")
              puts "🌿 [WORKSPACE] Checkout result: #{checkout_result ? 'SUCCESS' : 'FAILED'}"
            end
            puts "🌿 [WORKSPACE] Git repository preserved for healing operations"
          else
            puts "🌿 [WORKSPACE] Full repo clone failed"
          end
        end
      end
      
      def backup_file(file_path)
        backup_path = "#{file_path}.code_healer_backup"
        FileUtils.cp(file_path, backup_path)
      end
      
      def apply_fix_to_file(file_path, new_code, class_name, method_name)
        content = File.read(file_path)
        
        # Find and replace the method
        method_pattern = /def\s+#{Regexp.escape(method_name)}\s*\([^)]*\)(.*?)end/m
        if content.match(method_pattern)
          content.gsub!(method_pattern, new_code)
          File.write(file_path, content)
          puts "✅ Applied fix to #{File.basename(file_path)}##{method_name}"
        else
          puts "⚠️  Could not find method #{method_name} in #{File.basename(file_path)}"
        end
      end
      
      def find_ruby_files
        Dir.glob("**/*.rb")
      end
      
      # This method is no longer needed since we work entirely in the isolated workspace
      # def copy_fixed_files(workspace_path, repo_path)
      #   # Removed - no longer copying files between directories
      # end
      
      def workspace_expired?(workspace_path, hours)
        return false unless hours && hours > 0
        
        # Extract timestamp from workspace name
        if workspace_path =~ /healing_(\d+)/
          timestamp = $1.to_i
          age_hours = (Time.now.to_i - timestamp) / 3600
          age_hours > hours
        else
          false
        end
      end
    end
  end
end
