require 'fileutils'
require 'securerandom'

module CodeHealer
  # Manages isolated healing workspaces for safe code evolution
  class HealingWorkspaceManager
    class << self
      def create_healing_workspace(repo_path, branch_name = nil)
        puts "🏥 [WORKSPACE] Starting workspace creation..."
        puts "🏥 [WORKSPACE] Repo path: #{repo_path}"
        puts "🏥 [WORKSPACE] Target branch: #{branch_name || 'default'}"
        
        config = CodeHealer::ConfigManager.code_heal_directory_config
        puts "🏥 [WORKSPACE] Raw config: #{config.inspect}"
        
        base_path = config['path'] || config[:path] || '/tmp/code_healer_workspaces'
        puts "🏥 [WORKSPACE] Base heal dir: #{base_path}"
        
        # Use persistent workspace ID based on repo (if enabled)
        if CodeHealer::ConfigManager.persistent_workspaces_enabled?
          repo_name = extract_repo_name(repo_path)
          workspace_id = "persistent_#{repo_name}"
          workspace_path = File.join(base_path, workspace_id)
        else
          # Fallback to unique workspace for each healing session
          workspace_id = "healing_#{Time.now.to_i}_#{SecureRandom.hex(4)}"
          workspace_path = File.join(base_path, workspace_id)
        end
        
        if CodeHealer::ConfigManager.persistent_workspaces_enabled?
          puts "🏥 [WORKSPACE] Persistent workspace ID: #{workspace_id}"
        else
          puts "🏥 [WORKSPACE] Temporary workspace ID: #{workspace_id}"
        end
        puts "🏥 [WORKSPACE] Full workspace path: #{workspace_path}"
        
        begin
          puts "🏥 [WORKSPACE] Creating base directory..."
          # Ensure code heal directory exists
          FileUtils.mkdir_p(base_path)
          puts "🏥 [WORKSPACE] Base directory created/verified: #{base_path}"
          
          # Check if workspace already exists
          if Dir.exist?(workspace_path) && Dir.exist?(File.join(workspace_path, '.git'))
            if CodeHealer::ConfigManager.persistent_workspaces_enabled?
              puts "🏥 [WORKSPACE] Persistent workspace exists, checking out to target branch..."
              checkout_to_branch(workspace_path, branch_name, repo_path)
            else
              puts "🏥 [WORKSPACE] Workspace exists but persistent mode disabled, creating new one..."
              cleanup_workspace(workspace_path, true)
              create_persistent_workspace(repo_path, workspace_path, branch_name)
            end
          else
            puts "🏥 [WORKSPACE] Creating new workspace..."
            create_persistent_workspace(repo_path, workspace_path, branch_name)
          end
          
          puts "🏥 [WORKSPACE] Workspace ready successfully!"
          puts "🏥 [WORKSPACE] Final workspace path: #{workspace_path}"
          puts "🏥 [WORKSPACE] Current branch: #{get_current_branch(workspace_path)}"
          workspace_path
        rescue => e
          puts "❌ Failed to create/prepare healing workspace: #{e.message}"
          # Don't cleanup persistent workspace on error
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
            
            # Optionally skip heavy tests in demo mode
            unless CodeHealer::ConfigManager.demo_skip_tests?
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
            end
            
            puts "✅ Workspace validation passed"
            true
          end
        rescue => e
          puts "❌ Workspace validation failed: #{e.message}"
          false
        end
      end
      
      def validate_workspace_for_commit(workspace_path)
        puts "🔍 [WORKSPACE] Validating workspace for commit..."
        
        Dir.chdir(workspace_path) do
          # Check for any temporary files that might have been added
          staged_files = `git diff --cached --name-only`.strip.split("\n")
          working_files = `git status --porcelain | grep '^ M\\|^M \\|^A ' | awk '{print $2}'`.strip.split("\n")
          
          all_files = (staged_files + working_files).uniq.reject(&:empty?)
          
          puts "🔍 [WORKSPACE] Files to be committed: #{all_files.join(', ')}"
          
          # Check for any temporary files
          temp_files = all_files.select { |file| should_skip_file?(file) }
          
          if temp_files.any?
            puts "⚠️ [WORKSPACE] WARNING: Temporary files detected in commit:"
            temp_files.each { |file| puts "   - #{file}" }
            
            # Remove them from staging
            temp_files.each do |file|
              puts "🗑️ [WORKSPACE] Removing temporary file from staging: #{file}"
              system("git reset HEAD '#{file}' 2>/dev/null || true")
            end
            
            puts "🔍 [WORKSPACE] Temporary files removed from staging"
            return false
          end
          
          puts "✅ [WORKSPACE] Workspace validation passed - no temporary files detected"
          return true
        end
      rescue => e
        puts "❌ [WORKSPACE] Workspace validation failed: #{e.message}"
        return false
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
            add_only_relevant_files(workspace_path)
            
            # Validate workspace before commit to ensure no temporary files
            unless validate_workspace_for_commit(workspace_path)
              puts "⚠️ [WORKSPACE] Workspace validation failed, retrying file addition..."
              add_only_relevant_files(workspace_path)
            end
            
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
              
                          # Create pull request if auto-create is enabled
                          if should_create_pull_request?
                            puts "🔍 [WORKSPACE] Auto-creating pull request..."
                            pr_url = create_pull_request(healing_branch, branch_name)
                            if pr_url
                              puts "✅ [WORKSPACE] Pull request created: #{pr_url}"
                            else
                              puts "⚠️ [WORKSPACE] Failed to create pull request"
                            end
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
      
      def cleanup_workspace(workspace_path, force = false)
        puts "🧹 [WORKSPACE] Starting workspace cleanup..."
        puts "🧹 [WORKSPACE] Target: #{workspace_path}"
        puts "🧹 [WORKSPACE] Force cleanup: #{force}"
        puts "🧹 [WORKSPACE] Exists: #{Dir.exist?(workspace_path)}"
        
        return unless Dir.exist?(workspace_path)
        
        # Check if this is a persistent workspace
        is_persistent = workspace_path.include?('persistent_')
        
        if is_persistent && !force
          puts "🧹 [WORKSPACE] This is a persistent workspace - skipping cleanup"
          puts "🧹 [WORKSPACE] Use force=true to override"
          return
        end
        
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
          
          # Try to get GitHub token from environment
          github_token = ENV['GITHUB_TOKEN'] || ENV['GITHUB_ACCESS_TOKEN']
          
          unless github_token
            puts "❌ Missing GitHub token. Set GITHUB_TOKEN environment variable"
            puts "💡 You can create a token at: https://github.com/settings/tokens"
            return nil
          end
          
          # Auto-detect repository from git remote
          repo_name = detect_github_repository
          
          unless repo_name
            puts "❌ Could not detect GitHub repository from git remote"
            puts "💡 Make sure your repository has a GitHub remote origin"
            return nil
          end
          
          puts "🔗 Creating PR for repository: #{repo_name}"
          
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
          
          puts "✅ Pull request created successfully: #{pr.html_url}"
          pr.html_url
        rescue => e
          puts "❌ Failed to create pull request: #{e.message}"
          puts "💡 Check your GitHub token and repository access"
          nil
        end
      end

      def detect_github_repository
        # Try to detect from current git remote
        Dir.chdir(Dir.pwd) do
          remote_url = `git config --get remote.origin.url`.strip
          
          if remote_url.include?('github.com')
            # Extract owner/repo from GitHub URL
            if remote_url.include?('git@github.com:')
              # SSH format: git@github.com:owner/repo.git
              repo_part = remote_url.gsub('git@github.com:', '').gsub('.git', '')
            elsif remote_url.include?('https://github.com/')
              # HTTPS format: https://github.com/owner/repo.git
              repo_part = remote_url.gsub('https://github.com/', '').gsub('.git', '')
            else
              return nil
            end
            puts "🔍 Detected GitHub repository: #{repo_part}"
            return repo_part
          end
        end
        
        nil
      rescue
        nil
      end
      
      def extract_repo_name(repo_path)
        # Extract repo name from path or git remote
        if File.exist?(File.join(repo_path, '.git'))
          Dir.chdir(repo_path) do
            remote_url = `git config --get remote.origin.url`.strip
            if remote_url.include?('/')
              remote_url.split('/').last.gsub('.git', '')
            else
              File.basename(repo_path)
            end
          end
        else
          File.basename(repo_path)
        end
      end

      def create_persistent_workspace(repo_path, workspace_path, branch_name)
        puts "🏥 [WORKSPACE] Creating new persistent workspace..."
        
        # Get the GitHub remote URL
        Dir.chdir(repo_path) do
          remote_url = `git config --get remote.origin.url`.strip
          if remote_url.empty?
            puts "❌ [WORKSPACE] No remote origin found in #{repo_path}"
            return false
          end
          
          puts "🏥 [WORKSPACE] Cloning from: #{remote_url}"
          puts "🏥 [WORKSPACE] To workspace: #{workspace_path}"
          
          # Clone the full repository for persistent use
          result = system("git clone #{remote_url} #{workspace_path}")
          if result
            puts "🏥 [WORKSPACE] Repository cloned successfully"
            # Now checkout to the target branch
            checkout_to_branch(workspace_path, branch_name, repo_path)
          else
            puts "❌ [WORKSPACE] Failed to clone repository"
            return false
          end
        end
      end

      def checkout_to_branch(workspace_path, branch_name, repo_path)
        puts "🏥 [WORKSPACE] Checking out to target branch..."
        
        # Determine target branch
        target_branch = branch_name || CodeHealer::ConfigManager.pr_target_branch || get_default_branch(repo_path)
        puts "🏥 [WORKSPACE] Target branch: #{target_branch}"
        
        Dir.chdir(workspace_path) do
          # Fetch latest changes
          puts "🏥 [WORKSPACE] Fetching latest changes..."
          system("git fetch origin")
          
          # Check if branch exists locally
          local_branch_exists = system("git show-ref --verify --quiet refs/heads/#{target_branch}")
          
          if local_branch_exists
            puts "🏥 [WORKSPACE] Checking out existing local branch: #{target_branch}"
            system("git checkout #{target_branch}")
          else
            puts "🏥 [WORKSPACE] Checking out remote branch: #{target_branch}"
            system("git checkout -b #{target_branch} origin/#{target_branch}")
          end
          
          # Pull latest changes
          puts "🏥 [WORKSPACE] Pulling latest changes..."
          system("git pull origin #{target_branch}")
          
          # Ensure workspace is clean
          puts "🏥 [WORKSPACE] Ensuring workspace is clean..."
          system("git reset --hard HEAD")
          system("git clean -fd")
          
          # Remove any tracked temporary files that shouldn't be committed - AGGRESSIVE cleanup
          puts "🏥 [WORKSPACE] Removing tracked temporary files..."
          
          # Remove root level temporary directories
          system("git rm -r --cached tmp/ 2>/dev/null || true")
          system("git rm -r --cached log/ 2>/dev/null || true")
          system("git rm -r --cached .bundle/ 2>/dev/null || true")
          system("git rm -r --cached storage/ 2>/dev/null || true")
          system("git rm -r --cached coverage/ 2>/dev/null || true")
          system("git rm -r --cached .yardoc/ 2>/dev/null || true")
          system("git rm -r --cached .rspec_status 2>/dev/null || true")
          
          # Remove any nested tmp/ or log/ directories that might be tracked
          system("find . -name 'tmp' -type d -exec git rm -r --cached {} + 2>/dev/null || true")
          system("find . -name 'log' -type d -exec git rm -r --cached {} + 2>/dev/null || true")
          
          # Remove any .tmp, .log, .cache files
          system("find . -name '*.tmp' -exec git rm --cached {} + 2>/dev/null || true")
          system("find . -name '*.log' -exec git rm --cached {} + 2>/dev/null || true")
          system("find . -name '*.cache' -exec git rm --cached {} + 2>/dev/null || true")
          
          puts "🏥 [WORKSPACE] Successfully checked out to: #{target_branch}"
        end
      end

      def get_default_branch(repo_path)
        Dir.chdir(repo_path) do
          # Try to get default branch from remote
          default_branch = `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null`.strip
          if default_branch.include?('origin/')
            default_branch.gsub('refs/remotes/origin/', '')
          else
            # Fallback to common defaults
            ['main', 'master'].find { |branch| system("git ls-remote --heads origin #{branch} >/dev/null 2>&1") }
          end
        end
      end

      def get_current_branch(workspace_path)
        Dir.chdir(workspace_path) do
          `git branch --show-current`.strip
        end
      rescue
        'unknown'
      end

      def add_only_relevant_files(workspace_path)
        puts "📁 [WORKSPACE] Adding only relevant files, respecting .gitignore..."
        
        Dir.chdir(workspace_path) do
          # First, ensure .gitignore is respected
          if File.exist?('.gitignore')
            puts "📁 [WORKSPACE] Using repository's .gitignore file"
          else
            puts "📁 [WORKSPACE] No .gitignore found, using default patterns"
          end
          
          # Get list of modified files
          modified_files = `git status --porcelain | grep '^ M\\|^M \\|^A ' | awk '{print $2}'`.strip.split("\n")
          
          if modified_files.empty?
            puts "📁 [WORKSPACE] No modified files to add"
            return
          end
          
          puts "📁 [WORKSPACE] Modified files: #{modified_files.join(', ')}"
          
          # Add each modified file individually
          modified_files.each do |file|
            next if file.empty?
            
            # Skip temporary and generated files
            if should_skip_file?(file)
              puts "📁 [WORKSPACE] Skipping temporary file: #{file}"
              next
            end
            
            puts "📁 [WORKSPACE] Adding file: #{file}"
            system("git add '#{file}'")
          end
          
          puts "📁 [WORKSPACE] File addition completed"
        end
      end

      def should_skip_file?(file_path)
        # Skip temporary and generated files - AGGRESSIVE filtering
        skip_patterns = [
          # Root level directories - NEVER commit these
          /^tmp\//,
          /^log\//,
          /^\.git\//,
          /^node_modules\//,
          /^vendor\//,
          /^public\/packs/,
          /^public\/assets/,
          /^\.bundle\//,
          /^bootsnap/,
          /^cache/,
          /^storage\//,
          /^coverage\//,
          /^\.yardoc\//,
          /^\.rspec_status/,
          
          # Any tmp/ directory at any level
          /tmp\//,
          
          # Any log/ directory at any level  
          /log\//,
          
          # Specific tmp subdirectories
          /tmp\/cache\//,
          /tmp\/bootsnap\//,
          /tmp\/pids\//,
          /tmp\/sockets\//,
          /tmp\/sessions\//,
          /tmp\/backup\//,
          /tmp\/test\//,
          
          # File extensions
          /\.tmp$/,
          /\.log$/,
          /\.cache$/,
          /\.swp$/,
          /\.swo$/,
          /\.bak$/,
          /\.backup$/,
          /~$/,
          
          # Rails specific
          /\.bundle\//,
          /Gemfile\.lock\.backup/,
          /config\/database\.yml\.backup/,
          /config\/secrets\.yml\.backup/
        ]
        
        # Additional check: if path contains 'tmp' or 'log' anywhere, skip it
        if file_path.include?('tmp') || file_path.include?('log')
          puts "📁 [WORKSPACE] Skipping file containing 'tmp' or 'log': #{file_path}"
          return true
        end
        
        skip_patterns.any? { |pattern| file_path.match?(pattern) }
      end

      def reset_workspace_to_clean_state(workspace_path, branch_name = nil)
        puts "🔄 [WORKSPACE] Resetting workspace to clean state..."
        
        Dir.chdir(workspace_path) do
          # Stash any uncommitted changes
          puts "🔄 [WORKSPACE] Stashing any uncommitted changes..."
          system("git stash")
          
          # Reset to clean state
          puts "🔄 [WORKSPACE] Resetting to clean state..."
          system("git reset --hard HEAD")
          system("git clean -fd")
          
          # Checkout to target branch if specified
          if branch_name
            checkout_to_branch(workspace_path, branch_name, nil)
          end
          
          puts "🔄 [WORKSPACE] Workspace reset to clean state"
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
