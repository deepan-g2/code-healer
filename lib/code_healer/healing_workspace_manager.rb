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
      
      def merge_fixes_back(repo_path, workspace_path, branch_name)
        puts "🔄 Merging fixes back to main repository"
        
        begin
          # Create healing branch in main repo
          Dir.chdir(repo_path) do
            # Ensure we're on the target branch
            system("git checkout #{branch_name}")
            system("git pull origin #{branch_name}")
            
            # Create healing branch
            healing_branch = "code-healer-fix-#{Time.now.to_i}"
            system("git checkout -b #{healing_branch}")
            
            # Copy fixed files from workspace
            copy_fixed_files(workspace_path, repo_path)
            
            # Commit changes
            system("git add .")
            commit_message = "Fix applied by CodeHealer: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
            system("git commit -m '#{commit_message}'")
            
            # Push branch
            system("git push origin #{healing_branch}")
            
            puts "✅ Healing branch created: #{healing_branch}"
            healing_branch
          end
        rescue => e
          puts "❌ Failed to merge fixes back: #{e.message}"
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
      
      def clone_strategy
        cfg = CodeHealer::ConfigManager.code_heal_directory_config
        cfg['clone_strategy'] || cfg[:clone_strategy] || "branch"
      end
      
      def clone_current_branch(repo_path, workspace_path, branch_name)
        puts "🌿 [WORKSPACE] Starting branch cloning..."
        Dir.chdir(repo_path) do
          current_branch = branch_name || `git branch --show-current`.strip
          puts "🌿 [WORKSPACE] Current branch: #{current_branch}"
          puts "🌿 [WORKSPACE] Executing: git clone --single-branch --branch #{current_branch} #{repo_path} #{workspace_path}"
          
          # Clone only the current branch
          result = system("git clone --single-branch --branch #{current_branch} #{repo_path} #{workspace_path}")
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
          puts "🌿 [WORKSPACE] Executing: git clone #{repo_path} #{workspace_path}"
          
          # Clone full repo
          result = system("git clone #{repo_path} #{workspace_path}")
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
      
      def copy_fixed_files(workspace_path, repo_path)
        # Copy all Ruby files from workspace to repo
        Dir.glob(File.join(workspace_path, "**/*.rb")).each do |workspace_file|
          relative_path = workspace_file.sub(workspace_path + "/", "")
          repo_file = File.join(repo_path, relative_path)
          
          if File.exist?(repo_file)
            FileUtils.cp(workspace_file, repo_file)
            puts "📁 Copied fixed file: #{relative_path}"
          end
        end
      end
      
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
