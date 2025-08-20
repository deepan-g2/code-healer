#!/usr/bin/env ruby
# frozen_string_literal: true

# CodeHealer Interactive Setup Script
# This script helps users configure CodeHealer in their Rails applications

require 'fileutils'
require 'yaml'
require 'optparse'
require 'octokit'

# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: code_healer-setup [options]"
  
  opts.on("-h", "--help", "Show this help message") do
    puts opts
    puts
    puts "🏥 CodeHealer Setup Script"
    puts "This script helps you configure CodeHealer for your Rails application."
    puts
    puts "Examples:"
    puts "  code_healer-setup                    # Interactive setup"
    puts "  code_healer-setup --help            # Show this help"
    puts "  code_healer-setup --dry-run         # Show what would be created"
    puts
    exit 0
  end
  
  opts.on("--dry-run", "Show what would be created without making changes") do
    options[:dry_run] = true
  end
  
  opts.on("--version", "Show version information") do
    puts "CodeHealer Setup Script v1.0.0"
    exit 0
  end
end.parse!

# Helper methods for user interaction
def ask_for_input(prompt, default: nil)
  print "#{prompt} "
  input = gets.chomp.strip
  
  if input.empty? && default
    puts "Using default: #{default}"
    return default
  end
  
  input
end

def ask_for_yes_no(prompt, default: true)
  print "#{prompt} (#{default ? 'Y/n' : 'y/N'}) "
  input = gets.chomp.strip.downcase
  
  case input
  when 'y', 'yes'
    true
  when 'n', 'no'
    false
  when ''
    default
  else
    puts "Please enter 'y' or 'n'"
    ask_for_yes_no(prompt, default)
  end
end

def create_file_with_content(file_path, content, dry_run: false)
  if dry_run
    puts "📝 Would create #{file_path}"
    puts "   Content preview:"
    puts "   " + content.lines.first.strip + "..."
    return
  end
  
  FileUtils.mkdir_p(File.dirname(file_path))
  File.write(file_path, content)
  puts "✅ Created #{file_path}"
end

def file_exists?(file_path)
  File.exist?(file_path)
end

def read_file_content(file_path)
  File.read(file_path) if file_exists?(file_path)
end

def normalize_repository_url(repository_input, github_token = nil)
  return nil if repository_input.nil?
  input = repository_input.strip
  return nil if input.empty?

  # If it's already a URL, return as-is
  if input.include?('://')
    return input
  end

  # Build HTTPS URL from owner/repo
  base = "https://github.com/#{input}.git"
  return base if github_token.nil? || github_token.strip.empty?

  # Embed token for validation clone only (do not log the token)
  "https://#{github_token}@github.com/#{input}.git"
end

# Permission validation method
def validate_code_heal_directory_permissions(directory_path, repository_url, github_token = nil)
  puts "  📁 Checking directory: #{directory_path}"
  
  # Check if directory exists or can be created
  begin
    if Dir.exist?(directory_path)
      puts "    ✅ Directory exists"
    else
      puts "    🔨 Creating directory..."
      Dir.mkdir(directory_path)
      puts "    ✅ Directory created successfully"
    end
  rescue => e
    puts "    ❌ Cannot create directory: #{e.message}"
    return false
  end
  
  # Check write permissions
  begin
    test_file = File.join(directory_path, '.permission_test')
    File.write(test_file, 'test')
    File.delete(test_file)
    puts "    ✅ Write permissions verified"
  rescue => e
    puts "    ❌ Write permission failed: #{e.message}"
    return false
  end

  # If we have a token and a repo, verify push permissions via GitHub API
  if github_token && !github_token.strip.empty? && repository_url && !repository_url.strip.empty?
    begin
      client = Octokit::Client.new(access_token: github_token)
      repo_full_name = if repository_url.include?('github.com')
        path = repository_url.split('github.com/').last.to_s
        path.sub(/\.git\z/, '')
      else
        repository_url
      end
      repo = client.repository(repo_full_name)
      perms = (repo.respond_to?(:permissions) ? repo.permissions : repo[:permissions]) || {}
      can_push = perms[:push] == true || perms['push'] == true
      if can_push
        puts "    ✅ GitHub token has push permission to #{repo_full_name}"
      else
        puts "    ⚠️  GitHub token does not have push permission to #{repo_full_name}"
      end
    rescue => e
      puts "    ⚠️  Could not verify push permission via GitHub API: #{e.message}"
    end
  else
    puts "    ⚠️  Skipping GitHub push-permission check (missing token or repository)"
  end
  
  # Check if we can clone the repository (read access)
  puts "    🔍 Testing repository access..."
  begin
    require 'git'
    require 'fileutils'
    
    # Create a temporary test directory
    test_dir = File.join(directory_path, 'test_clone_' + Time.now.to_i.to_s)
    
    # Try to clone the repository
    puts "    📥 Attempting to clone repository..."
    # Avoid printing token in logs
    safe_url = repository_url.to_s.gsub(/:\/\/[A-Za-z0-9_\-]+@/, '://***@')
    # Perform clone
    Git.clone(repository_url, test_dir, depth: 1)
    
    # Clean up test clone
    FileUtils.rm_rf(test_dir)
    puts "    ✅ Repository access verified (#{safe_url})"
    
    return true
  rescue => e
    puts "    ❌ Repository access failed: #{e.message}"
    puts "    💡 Make sure:"
    puts "       - Your GitHub token has repo access"
    puts "       - The repository URL is correct (e.g., https://github.com/owner/repo.git or owner/repo)"
    puts "       - You have network access to GitHub"
    return false
  end
end

# Main setup logic
puts "🏥 Welcome to CodeHealer Setup! 🚀"
puts "=" * 50
puts "This will help you configure CodeHealer for your Rails application."
puts

# Check if we're in a Rails app
unless file_exists?('Gemfile') && file_exists?('config/application.rb')
  puts "❌ Error: This doesn't appear to be a Rails application."
  puts "Please run this script from your Rails application root directory."
  exit 1
end

puts "✅ Rails application detected!"
puts

# Step 1: Add to Gemfile
puts "📦 Step 1: Adding CodeHealer to Gemfile..."
gemfile_path = 'Gemfile'
gemfile_content = read_file_content(gemfile_path)

if gemfile_content.include?("gem 'code_healer'")
  puts "✅ CodeHealer already in Gemfile"
else
  # Add the gem to the Gemfile
  new_gemfile_content = gemfile_content + "\n# CodeHealer - AI-powered code healing\ngem 'code_healer'\n"
  
  if options[:dry_run]
    puts "📝 Would add 'code_healer' to Gemfile"
  else
    File.write(gemfile_path, new_gemfile_content)
  puts "✅ Added 'code_healer' to Gemfile"
  end
end

puts

# Step 2: Configuration Setup
puts "🔧 Step 2: Configuration Setup"
puts

# OpenAI Configuration
puts "🤖 OpenAI Configuration:"
puts "You'll need an OpenAI API key for AI-powered code healing."
puts "Get one at: https://platform.openai.com/api-keys"
puts

openai_key = ask_for_input("Enter your OpenAI API key (or press Enter to skip for now):")

# GitHub Configuration
puts
puts "🐙 GitHub Configuration:"
puts "You'll need a GitHub personal access token for Git operations."
puts "Get one at: https://github.com/settings/tokens"
puts

github_token = ask_for_input("Enter your GitHub personal access token (or press Enter to skip for now):")
github_repo = ask_for_input("Enter your GitHub repository (username/repo or full URL):")
github_repo_url = normalize_repository_url(github_repo, github_token)

# Git Branch Configuration
puts
puts "🌿 Git Branch Configuration:"
branch_prefix = ask_for_input("Enter branch prefix for healing branches (default: evolve):", default: "evolve")
pr_target_branch = ask_for_input("Enter target branch for pull requests (default: main):", default: "main")

# Code Heal Directory Configuration
puts
puts "🏥 Code Heal Directory Configuration:"
puts "This directory will store isolated copies of your code for safe healing."
puts "CodeHealer will clone your current branch here before making fixes."
puts

code_heal_directory = ask_for_input("Enter code heal directory path (default: /tmp/code_healer_workspaces):", default: "/tmp/code_healer_workspaces")

# Validate code heal directory permissions
puts "🔍 Validating code heal directory permissions..."
if github_repo_url && !github_repo_url.strip.empty?
  if validate_code_heal_directory_permissions(code_heal_directory, github_repo_url, github_token)
    puts "✅ Code heal directory permissions validated successfully!"
  else
    puts "❌ Code heal directory permission validation failed!"
    puts "Please ensure the directory has proper write permissions and can access the repository."
    code_heal_directory = ask_for_input("Enter a different code heal directory path:", default: "/tmp/code_healer_workspaces")
    
    # Retry validation
    if validate_code_heal_directory_permissions(code_heal_directory, github_repo_url, github_token)
      puts "✅ Code heal directory permissions validated successfully!"
    else
      puts "⚠️  Permission validation failed again. You may need to fix permissions manually."
    end
  end
else
  puts "⚠️  Skipping repository access validation (no repository URL provided)"
  puts "   Directory permissions will be validated when you run the actual setup"
end

auto_cleanup = ask_for_yes_no("Automatically clean up healing workspaces after use?", default: true)
cleanup_after_hours = ask_for_input("Clean up workspaces after how many hours? (default: 24):", default: "24")

# Business Context
puts
puts "💼 Business Context Setup:"
create_business_context = ask_for_yes_no("Would you like to create a business context file?", default: true)

# Evolution Strategy Configuration
puts
puts "🧠 Evolution Strategy Configuration:"
puts "Choose how CodeHealer should fix your code:"
puts "1. API - Use OpenAI API (recommended for most users)"
puts "2. Claude Code Terminal - Use local Claude installation"
puts "3. Hybrid - Try Claude first, fallback to API"
puts

evolution_method = ask_for_input("Enter evolution method (1/2/3 or api/claude/hybrid):", default: "api")
evolution_method = case evolution_method.downcase
                   when "1", "api"
                     "api"
                   when "2", "claude"
                     "claude_code_terminal"
                   when "3", "hybrid"
                     "hybrid"
                   else
                     "api"
                   end

fallback_to_api = ask_for_yes_no("Fallback to API if Claude Code fails?", default: true)

# Create configuration files
puts
puts "📝 Step 3: Creating Configuration Files"
puts

# Create actual .env file (will be ignored by git)
  env_content = <<~ENV
  # CodeHealer Configuration
    # OpenAI Configuration
  OPENAI_API_KEY=#{openai_key}
    
    # GitHub Configuration
  GITHUB_TOKEN=#{github_token}
  GITHUB_REPOSITORY=#{github_repo}
  
  # Optional: Redis Configuration
  REDIS_URL=redis://localhost:6379/0
ENV

create_file_with_content('.env', env_content, dry_run: options[:dry_run])

# Create code_healer.yml
  config_content = <<~YAML
    # CodeHealer Configuration
    enabled: true
    
  # Allowed classes for healing (customize as needed)
    allowed_classes:
      - User
      - Order
      - PaymentProcessor
    - OrderProcessor
    
  # Excluded classes (never touch these)
    excluded_classes:
      - ApplicationController
      - ApplicationRecord
      - ApplicationJob
      - ApplicationMailer
    - ApplicationHelper
    
    # Allowed error types for healing
    allowed_error_types:
    - ZeroDivisionError
    - NoMethodError
      - ArgumentError
    - TypeError
      - NameError
      - ValidationError
    
  # Evolution Strategy Configuration
    evolution_strategy:
    method: #{evolution_method}  # Options: api, claude_code_terminal, hybrid
    fallback_to_api: #{fallback_to_api}  # If Claude Code fails, fall back to API
    
  # Claude Code Terminal Configuration
    claude_code:
    enabled: #{evolution_method == 'claude_code_terminal' || evolution_method == 'hybrid'}
    timeout: 300  # Timeout in seconds
      max_file_changes: 10
      include_tests: true
    command_template: "claude --print '{prompt}' --output-format text --permission-mode acceptEdits --allowedTools Edit"
      business_context_sources:
        - "config/business_rules.yml"
        - "docs/business_logic.md"
        - "spec/business_context_specs.rb"
    
  # Business Context Configuration
    business_context:
      enabled: true
    sources:
      - "docs/business_rules.md"
    
    # OpenAI API configuration
    api:
      provider: openai
    model: gpt-4
      max_tokens: 2000
      temperature: 0.1
    
    # Git operations
    git:
      auto_commit: true
      auto_push: true
    branch_prefix: "#{branch_prefix}"
    commit_message_template: 'Fix {{class_name}}\#\#{{method_name}}: {{error_type}}'
    pr_target_branch: "#{pr_target_branch}"
  
  # Pull Request Configuration
    pull_request:
      enabled: true
      auto_create: true
      labels:
        - "auto-fix"
      - "self-evolving"
        - "bug-fix"
    
  # Safety Configuration
  safety:
    backup_before_evolution: true
    rollback_on_syntax_error: true
  
  # Evolution Limits
  max_evolutions_per_day: 10
  
  # Notification Configuration (optional)
  notifications:
    enabled: false
    slack_webhook: ""
    email_notifications: false
  
  # Performance Configuration
  performance:
    max_concurrent_healing: 3
    healing_timeout: 300
    retry_attempts: 3
  
  # Code Heal Directory Configuration
  code_heal_directory:
    path: "#{code_heal_directory}"
    auto_cleanup: #{auto_cleanup}
    cleanup_after_hours: #{cleanup_after_hours}
    max_workspaces: 10
    clone_strategy: "branch"  # Options: branch, full_repo
YAML

create_file_with_content('config/code_healer.yml', config_content, dry_run: options[:dry_run])

# Create business context file if requested
if create_business_context
  business_context_content = <<~MARKDOWN
    # Business Rules and Context
    
    ## Error Handling
    - All errors should be logged for audit purposes
    - User-facing errors should be user-friendly
    - Critical errors should trigger alerts
    
    ## Data Validation
    - All user inputs must be validated
    - Business rules must be enforced
    - Invalid data should be rejected with clear messages
    
    ## Security
    - Authentication required for sensitive operations
    - Input sanitization mandatory
    - Rate limiting for API endpoints
    
    ## Business Logic
    - Follow domain-specific business rules
    - Maintain data consistency
    - Log all business-critical operations
  MARKDOWN
  
  create_file_with_content('docs/business_rules.md', business_context_content, dry_run: options[:dry_run])
end

# Create Sidekiq configuration
puts
puts "⚡ Step 4: Sidekiq Configuration"
puts

sidekiq_config_content = <<~YAML
  :concurrency: 5
  :queues:
    - [healing, 2]
    - [default, 1]
  
  :redis:
    :url: <%= ENV['REDIS_URL'] || 'redis://localhost:6379/0' %>
  
  :logfile: log/sidekiq.log
  :pidfile: tmp/pids/sidekiq.pid
YAML

create_file_with_content('config/sidekiq.yml', sidekiq_config_content, dry_run: options[:dry_run])

# Permission validation method moved to top of file

# Final instructions
puts
if options[:dry_run]
  puts "🔍 Dry Run Complete! 🔍"
  puts "=" * 50
  puts "This is what would be created. Run without --dry-run to actually create the files."
else
  puts "🎉 Setup Complete! 🎉"
  puts "=" * 50
  puts "Next steps:"
  puts "1. Install dependencies: bundle install"
  puts "2. Start Redis: redis-server"
  puts "3. Start Sidekiq: bundle exec sidekiq"
  puts "4. Start your Rails server: rails s"
  puts
  puts "🔒 Security Notes:"
puts "   - .env file contains your actual API keys and is ignored by git"
puts "   - .env.example is safe to commit and shows the required format"
puts "   - Never commit .env files with real secrets to version control"
puts
puts "🏥 Code Heal Directory:"
puts "   - Your code will be cloned to: #{code_heal_directory}"
puts "   - This ensures safe, isolated healing without affecting your running server"
puts "   - Workspaces are automatically cleaned up after #{cleanup_after_hours} hours"
puts
puts "⚙️  Configuration:"
puts "   - code_healer.yml contains comprehensive settings with sensible defaults"
puts "   - Customize the configuration file as needed for your project"
puts "   - All features are pre-configured and ready to use"
  puts
  puts "🌍 Environment Variables:"
  puts "   - Add 'gem \"dotenv-rails\"' to your Gemfile for automatic .env loading"
  puts "   - Or export variables manually: export GITHUB_TOKEN=your_token"
  puts "   - Or load .env file in your application.rb: load '.env' if File.exist?('.env')"
  puts
  puts "CodeHealer will now automatically detect and heal errors in your application!"
end

puts
puts "📚 For more information, visit: https://github.com/deepan-g2/code-healer"
puts "📧 Support: support@code-healer.com"
puts
puts "Happy coding! 🚀"
