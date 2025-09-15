require 'timeout'
require 'open3'
require_relative 'presentation_logger'

module CodeHealer
  class ClaudeCodeEvolutionHandler
    class << self
      def handle_error_with_claude_code(error, class_name, method_name, file_path)
        PresentationLogger.section("Claude Code Terminal – Evolution")
        PresentationLogger.kv("Error", "#{error.class}: #{error.message}")
        PresentationLogger.kv("Target", "#{class_name}##{method_name}")
        PresentationLogger.detail("File: #{file_path}")
        
        begin
          # Build concise prompt
          prompt = BusinessContextManager.build_claude_code_prompt(
            error, class_name, method_name, file_path
          )

          prompt << "\n\nStrict instructions:" \
                   "\n- Do NOT scan the entire codebase." \
                   "\n- Work only with the provided file/method context and backtrace." \
                   "\n- Return a unified diff (no prose)." \
                   "\n- Keep changes minimal and safe."
          
          # Execute Claude Code command
          success = execute_claude_code_fix(prompt, class_name, method_name)
          
          if success
            PresentationLogger.success("Claude run completed")
            reload_modified_files
            # Run targeted RSpec and iterate on failures
            return run_tests_and_iterate_fixes(class_name, method_name)
          else
            PresentationLogger.error("Claude run failed")
            return false
          end
          
        rescue => e
          PresentationLogger.error("Claude evolution error: #{e.message}")
          PresentationLogger.detail("Backtrace: #{Array(e.backtrace).first(5).join("\n")}")
          return false
        end
      end
      
      private
      
      def execute_claude_code_fix(prompt, class_name, method_name)
        config = ConfigManager.claude_code_settings
        
        # Build command
        command = build_claude_command(prompt, config)
        
        PresentationLogger.claude_action("Executing Claude Code (timeout: #{config['timeout']}s)")
        
        begin
          # Execute with timeout
          Timeout.timeout(config['timeout']) do
            stdout, stderr, status = Open3.capture3(command)
            
            if stdout && !stdout.empty?
              PresentationLogger.success("Response received from Claude")
              PresentationLogger.detail(stdout)



              # Business context references are intentionally not logged

              # Check if Claude Code is asking for permission
              if stdout.include?("permission") || stdout.include?("grant") || stdout.include?("edit")
                PresentationLogger.warn("Claude requested edit permissions. Ensure permissions are granted.")
              end
              
              # Check if fix was applied
              if stdout.include?("fix") && (stdout.include?("applied") || stdout.include?("ready"))
                puts "🎯 Fix appears to be ready - checking if files were modified..."
              end
            else
              PresentationLogger.warn("No output received from Claude")
            end

            if stderr && !stderr.empty?
              PresentationLogger.warn("Claude warnings/errors present")
              PresentationLogger.detail(stderr)
            end
            
            if status.success?
              PresentationLogger.success("Claude execution succeeded")
              return true
            else
              PresentationLogger.error("Claude execution failed (status #{status.exitstatus})")
              return false
            end
          end
          
        rescue Timeout::Error
          PresentationLogger.error("Claude execution timed out after #{config['timeout']}s")
          return false
        rescue => e
          PresentationLogger.error("Claude execution error: #{e.message}")
          return false
        end
      end
      
      def build_claude_command(prompt, config)
        # Escape prompt for shell
        escaped_prompt = prompt.gsub("'", "'\"'\"'")
    
        # Build command template for MCP tools access
        command_template = config['command_template'] || "claude --print '{prompt}' --output-format text --allowedTools Edit,mcp__atlassian"
    
        # Replace placeholder
        command = command_template.gsub('{prompt}', escaped_prompt)
    
        # Add limits and testing hints
        if config['include_tests']
          command += " --append-system-prompt 'Include tests when fixing the code'"
        end
        
        if config['max_file_changes']
          command += " --append-system-prompt 'Limit changes to #{config['max_file_changes']} files maximum'"
        end
    
        # Add business context instructions and require a delimited summary we can parse (Confluence only)
        # command += " --append-system-prompt 'CRITICAL: Before fixing any code, use the Atlassian MCP tools to fetch business context from Confluence ONLY. Summarize the relevant findings in a concise, bullet list between the markers <<CONTEXT_START>> and <<CONTEXT_END>>. Include Confluence page titles and links, and key rules. Keep to <=5 bullets. Then proceed with the fix.'"

        # Explicit Confluence page fetch (env override with default fallback)
        explicit_confluence_page_id = (ENV['CONFLUENCE_PAGE_ID'] || '4949770295').to_s.strip
        unless explicit_confluence_page_id.empty?
          command += " --append-system-prompt 'CRITICAL: Before fixing any code, Explicitly fetch Confluence page ID #{explicit_confluence_page_id} using Atlassian MCP (mcp__atlassian), extract applicable business logic/rules, and APPLY those rules in the fix.'"
        end
          
        # Return command
        command
      end

      # Run targeted specs for changed files and iterate fixes up to a configured limit
      def run_tests_and_iterate_fixes(class_name, method_name)
        max_iters = ConfigManager.max_test_fix_iterations
        it = 0
        loop do
          it += 1
          PresentationLogger.step("RSpec run #{it}/#{max_iters}")
          failures = run_targeted_rspec_for_changes
          if failures.nil?
            PresentationLogger.warn("No RSpec detected or no changed files with specs. Skipping test loop.")
            return true
          end
          if failures.empty?
            PresentationLogger.success("All targeted specs passed")
            return true
          end
          PresentationLogger.warn("Failures detected (#{failures.size}). Attempting fix iteration...")
          break if it >= max_iters
          attempt_fix_from_failures(failures, class_name, method_name)
        end
        PresentationLogger.warn("Reached max test-fix iterations (#{max_iters}).")
        false
      end

      def run_targeted_rspec_for_changes
        changed = get_recently_modified_files.select { |f| f.end_with?('.rb') }
        spec_files = changed.map { |f| f.sub(%r{^app/}, 'spec/').sub(/\.rb\z/, '_spec.rb') }
        spec_files.select! { |s| File.exist?(s) }
        return nil if spec_files.empty? || !File.exist?('spec')
        cmd = ["bundle exec rspec --format documentation --no-color", spec_files.map { |s| "'#{s}'" }.join(' ')].join(' ')
        stdout, stderr, status = Open3.capture3(cmd)
        PresentationLogger.detail(stdout) if stdout && !stdout.empty?
        PresentationLogger.warn(stderr) if stderr && !stderr.empty?
        parse_rspec_failures(stdout)
      rescue => e
        PresentationLogger.warn("RSpec execution failed: #{e.message}")
        nil
      end

      def parse_rspec_failures(output)
        return [] unless output
        failures = []
        current = nil
        output.each_line do |line|
          if line =~ /^\s*\d+\)\s+(.*)$/
            current = { title: $1.strip, details: [] }
            failures << current
          elsif current
            current[:details] << line
          end
        end
        failures
      end

      def attempt_fix_from_failures(failures, class_name, method_name)
        summary = failures.map { |f| "- #{f[:title]}\n  #{f[:details].first(5).join}" }.join("\n")
        PresentationLogger.claude_action("Sending failure summary to Claude for iterative fix")
        iterative_prompt = <<~PROMPT
          The previous fix compiled, but targeted RSpec tests failed. Here is a concise failure summary:\n\n#{summary}\n\nUpdate the relevant code to make these tests pass. Return only a unified diff. Keep changes minimal and safe.
        PROMPT
        config = ConfigManager.claude_code_settings
        command = build_claude_command(iterative_prompt, config)
        stdout, stderr, status = Open3.capture3(command)
        PresentationLogger.detail(stdout) if stdout && !stdout.empty?
        PresentationLogger.warn(stderr) if stderr && !stderr.empty?
        if status.success?
          PresentationLogger.success("Iterative Claude run succeeded")
          reload_modified_files
          true
        else
          PresentationLogger.error("Iterative Claude run failed (status #{status.exitstatus})")
          false
        end
      end
      
      # Parse Claude Terminal output for Confluence links/titles (Confluence only)
      def extract_business_context_references(text)
        refs = []
        return refs unless text
        
        # Match Confluence URLs
        confluence_regex = /(https?:\/\/[^\s]+confluence[^\s]+\/(display|spaces|pages)\/[^\s)"']+)/i
        text.scan(confluence_regex).each do |match|
          url = match[0]
          title = url.split('/').last.gsub('-', ' ')[0..80]
          refs << { source: 'Confluence', display: "#{title} (#{url})" }
        end
        
        refs.uniq { |r| r[:display] }
      end
      
      def reload_modified_files
        PresentationLogger.step("Reloading modified files")
        
        # Get list of recently modified files (last 5 minutes)
        recent_files = get_recently_modified_files
        
        recent_files.each do |file_path|
          if file_path.include?('/app/')
            begin
              load file_path
              PresentationLogger.detail("Reloaded: #{file_path}")
            rescue => e
              PresentationLogger.warn("Failed to reload #{file_path}: #{e.message}")
            end
          end
        end
        
        PresentationLogger.detail("File reloading completed")
      end
      
      def get_recently_modified_files
        # Get files modified in the last 5 minutes
        cutoff_time = Time.now - 300 # 5 minutes ago
        
        files = []
        Dir.glob('**/*.rb').each do |file|
          if File.mtime(file) > cutoff_time
            files << file
          end
        end
        
        files.sort_by { |f| File.mtime(f) }.reverse
      end
      
      def log_evolution_attempt(error, class_name, method_name, success)
        log_entry = {
          timestamp: Time.now.iso8601,
          method: 'claude_code_terminal',
          error_type: error.class.name,
          error_message: error.message,
          class_name: class_name,
          method_name: method_name,
          success: success,
          execution_time: Time.now
        }
        
        # Log to file
        log_file = 'log/claude_code_evolution.log'
        FileUtils.mkdir_p(File.dirname(log_file))
        
        File.open(log_file, 'a') do |f|
          f.puts(log_entry.to_json)
        end
        
        PresentationLogger.detail("Evolution attempt logged to #{log_file}")
      end
      

      
      def trigger_git_operations(error, class_name, method_name, file_path)
        puts "🚀 Triggering Git operations for Claude Code evolution..."
        
        begin
          # Use the existing SimpleEvolution Git operations
          require_relative 'simple_evolution'
          
          # Create a mock business context for Git operations
          business_context = {
            error_type: error.class.name,
            error_message: error.message,
            class_name: class_name,
            method_name: method_name
          }
          
          # Trigger the Git operations through SimpleEvolution
          git_success = CodeHealer::SimpleEvolution.handle_git_operations_for_claude(
            error, class_name, method_name, file_path
          )
          
          if git_success
            puts "✅ Git operations completed successfully!"
            puts "   - Branch created and committed"
            puts "   - Changes pushed to remote"
            puts "   - Pull request created"
          else
            puts "❌ Git operations failed"
          end
          
        rescue => e
          puts "❌ Error during Git operations: #{e.message}"
          puts "💡 You may need to manually commit and create PR"
        end
      end
    end
  end
end
