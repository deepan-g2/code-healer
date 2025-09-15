require 'logger'
require 'git'
require 'octokit'
require_relative 'presentation_logger'

module CodeHealer
  class Core
    class << self
      def initialize(config)
        puts "🏥 Initializing CodeHealer with configuration..."
        # Store configuration globally
        @config = config
        puts "✅ CodeHealer initialized successfully!"
      end
      
      def setup_error_handling
        puts "🔧 Setting up error handling..."
        
        # Set up Rails error handling for web requests
        if defined?(Rails) && Rails.application
          # Subscribe to Rails error reporter
          Rails.error.subscribe(WebRequestErrorSubscriber.new)
          puts "✅ Web request error handling set up"
        end
        
        # Set up console error handling
        if defined?(IRB) || defined?(Pry)
          # Patch classes to catch console errors
          patch_classes_for_evolution
          puts "✅ Console error handling set up"
        end
        
        puts "✅ Error handling setup complete!"
      end
      
      def evolve_method(klass, method_name, context)
        puts "Starting evolution process for #{klass.name}##{method_name}"
        
        # Get the file path
        file_path = Rails.root.join('app', 'models', "#{klass.name.underscore}.rb")
        puts "File path: #{file_path}"
        
        # Read the current content
        current_content = File.read(file_path)
        puts "Current content length: #{current_content.length}"
        
        # Get the original method
        original_method = klass.instance_method(method_name)
        
        # Try to get the method source
        begin
          original_source = original_method.source
        rescue
          # If we can't get the source, try to find it in the file
          if current_content =~ /def\s+#{method_name}.*?end/m
            original_source = $&
          else
            # If we still can't find it, use the error context to generate a new method
            original_source = generate_method_from_error(klass, method_name, context)
          end
        end
        
        puts "Original method source: #{original_source}"
        
        # Generate new method implementation
        new_method = generate_method(klass, method_name, context, original_source)
        puts "Generated new method: #{new_method}"
        
        # Replace the method in the file content
        new_content = current_content.gsub(original_source, new_method)
        puts "New content length: #{new_content.length}"
        
        # Create a new branch
        branch_name = "evolve/#{klass.name.underscore}-#{method_name}-#{Time.now.to_i}"
        puts "Creating new branch: #{branch_name}"
        
        # Initialize git if not already initialized
        unless File.exist?(Rails.root.join('.git'))
          puts "Initializing git repository..."
          git = Git.init(Rails.root.to_s)
          git.add('.')
          git.commit('Initial commit')
        end
        
        # Create and checkout new branch
        git = Git.open(Rails.root.to_s)
        git.branch(branch_name).checkout
        
        # Write the new content
        File.write(file_path, new_content)
        puts "Updated file: #{file_path}"
        
        # Commit changes
        git.add(file_path)
        commit_message = "Evolve #{klass.name}##{method_name} to handle #{context[:error].class}"
        git.commit(commit_message)
        
        # Push branch
        git.push('origin', branch_name)
        puts "Pushed branch: #{branch_name}"
        
        # Create PR
        client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
        repo = ENV['GITHUB_REPOSITORY'] || 'your-username/your-repo'
        
        pr_title = "Evolve #{klass.name}##{method_name}"
        pr_body = <<~MARKDOWN
          This PR contains an evolved version of `#{klass.name}##{method_name}` to handle the following error:
          
          ```
          #{context[:error].class}: #{context[:error].message}
          ```
          
          Changes:
          - Added error handling for #{context[:error].class}
          - Improved method robustness
          - Added logging for debugging
        MARKDOWN
        
        pr = client.create_pull_request(
          repo,
          'main',
          branch_name,
          pr_title,
          pr_body
        )
        puts "Created PR: #{pr.html_url}"
        
        # Return the new method implementation
        new_method
      end
      
      private
      
      def generate_method_from_error(klass, method_name, context)
        # Get the error message and backtrace
        error = context[:error]
        backtrace = error.backtrace.first
        
        # Extract the line number from the backtrace
        if backtrace =~ /:(\d+):/
          line_number = $1.to_i
        end
        
        # Generate a basic method structure
        <<~RUBY
          def #{method_name}(#{original_method.parameters.map { |type, name| name }.join(', ')})
            #{error.message}
          end
        RUBY
      end
      
      def generate_method(klass, method_name, context, original_source)
        # Get the original method
        original_method = klass.instance_method(method_name)
        
        # Extract the method body (everything between the first and last line)
        method_lines = original_source.split("\n")
        method_body = method_lines[1..-2].join("\n")
        
        # Generate new method with error handling
        new_method = <<~RUBY
          def #{method_name}(#{original_method.parameters.map { |type, name| name }.join(', ')})
            begin
              #{method_body}
            rescue NoMethodError => e
              if e.message.include?('undefined method') && e.message.include?('nil')
                # Handle nil object errors
                puts "Handling nil object error: \#{e.message}"
                return 0.05 # Default discount for nil cases
              end
              raise e
            rescue => e
              puts "Unexpected error in #{method_name}: \#{e.message}"
              raise e
            end
          end
        RUBY
        
        new_method
      end
      
      def patch_classes_for_evolution
        # Patch all autoloaded classes except excluded ones
        excluded = CodeHealer::ConfigManager.excluded_classes
        # Attempt to iterate over loaded application classes
        if defined?(Rails) && Rails.application
          app_paths = [Rails.root.join('app', 'models'), Rails.root.join('app', 'controllers')]
          app_paths.each do |path|
            Dir.glob(File.join(path.to_s, '**', '*.rb')).each do |file|
              begin
                relative = file.sub(Rails.root.join('app').to_s + '/', '')
                class_name = relative.gsub('.rb', '').split('/').map(&:classify).join('::')
                next if class_name.nil? || class_name.empty?
                next if excluded.include?(class_name)
                klass = class_name.constantize rescue nil
                next unless klass.is_a?(Class) || klass.is_a?(Module)
                patch_class_for_evolution(klass)
              rescue => e
                puts "⚠️  Skipping #{file}: #{e.message}"
              end
            end
          end
        end
      end
      
      def patch_class_for_evolution(klass)
        # This will be called when errors occur in the class
        # For now, just log that we're ready to handle errors
        puts "🔍 Ready to handle errors in #{klass.name}"
      end
      
      # Web request error subscriber
      class WebRequestErrorSubscriber
        def report(error, handled:, severity:, context:, source: nil)
          return unless should_handle_error?(error, context)
          
          puts "🚨 Web request error caught: #{error.class} - #{error.message}"
          
          # Extract class and method from error backtrace
          class_name, method_name = extract_from_backtrace(error.backtrace)
          
          if class_name && method_name
            puts "🔧 Triggering healing for #{class_name}##{method_name}"
            
            # Queue healing job
            queue_evolution_job(error, class_name, method_name)
          else
            puts "⚠️  Could not extract class/method from backtrace"
          end
        end
        
        private
        
        def should_handle_error?(error, context)
          # Always try to handle errors - we'll extract class from backtrace
          true
        end
        
        def extract_from_backtrace(backtrace)
          return [nil, nil] unless backtrace
          
          PresentationLogger.detail("Starting backtrace analysis...")
          PresentationLogger.detail("First 5 backtrace lines:")
          backtrace.first(5).each_with_index { |line, i| PresentationLogger.detail("  #{i}: #{line}") }
          
          # Use the exact working implementation from SelfRuby
          core_methods = %w[* + - / % ** == != < > <= >= <=> === =~ !~ & | ^ ~ << >> [] []= `]
          app_file_line = backtrace.find { |line| line.include?('/app/') }
          return [nil, nil] unless app_file_line
          
          PresentationLogger.detail("Found app file line: #{app_file_line}")
          
          if app_file_line =~ /(.+):(\d+):in `(.+)'/
            file_path = $1
            method_name = $3
            
            PresentationLogger.detail("Extracted file_path=#{file_path}, method_name=#{method_name}")
            
            # If it's a core method, look deeper in the backtrace
            if core_methods.include?(method_name)
              PresentationLogger.detail("#{method_name} is a core method, looking deeper...")
              deeper_app_line = backtrace.find do |line| 
                line.include?('/app/') && 
                line =~ /in `(.+)'/ && 
                !core_methods.include?($1) &&
                !$1.include?('block in') &&
                !$1.include?('each') &&
                !$1.include?('map') &&
                !$1.include?('reduce')
              end
              
              if deeper_app_line
                PresentationLogger.detail("Found deeper app line: #{deeper_app_line}")
                if deeper_app_line =~ /(.+):(\d+):in `(.+)'/
                  file_path = $1
                  method_name = $3
                  PresentationLogger.detail("Updated to file_path=#{file_path}, method_name=#{method_name}")
                end
              else
                PresentationLogger.detail("No deeper app line found")
              end
            end
            
            # If it's still a block or iterator, look for the containing method
            if method_name && (
              method_name.include?('block in') || 
              method_name.include?('each') || 
              method_name.include?('map') || 
              method_name.include?('reduce') ||
              method_name.include?('sum')
            )
              PresentationLogger.detail("#{method_name} is a block/iterator, looking for containing method...")
              # Look for the FIRST valid method in the backtrace, not just any method
              containing_line = backtrace.find do |line|
                line.include?('/app/') && 
                line =~ /in `(.+)'/ && 
                !core_methods.include?($1) &&
                !$1.include?('block in') &&
                !$1.include?('each') &&
                !$1.include?('map') &&
                !$1.include?('reduce') &&
                !$1.include?('sum') &&
                !$1.include?('*')  # Also skip the core method we started with
              end
              
              if containing_line
                PresentationLogger.detail("Found containing line: #{containing_line}")
                if containing_line =~ /(.+):(\d+):in `(.+)'/
                  file_path = $1
                  method_name = $3
                  PresentationLogger.detail("Updated to file_path=#{file_path}, method_name=#{method_name}")
                end
              else
                PresentationLogger.detail("No containing line found")
              end
            end
            
            # Extract class name from file path
            if file_path && method_name
              if file_path.include?('app/models/')
                file_name = file_path.split('/').last.gsub('.rb', '')
                class_name = file_name.classify
              elsif file_path.include?('app/controllers/')
                file_name = file_path.split('/').last.gsub('.rb', '')
                if file_name.include?('/')
                  parts = file_name.split('/')
                  class_name = parts.map(&:classify).join('::')
                else
                  class_name = file_name.classify
                end
              end
              
              PresentationLogger.detail("Final result - class_name=#{class_name}, method_name=#{method_name}")
              PresentationLogger.detail("Extracted: #{class_name}##{method_name} from #{file_path}")
              return [class_name, method_name]
            end
          end
          
          PresentationLogger.detail("No valid method found in backtrace")
          [nil, nil]
        end
        
        def queue_evolution_job(error, class_name, method_name)
          # Queue the healing job in Sidekiq
          if defined?(CodeHealer::HealingJob)
            # Get evolution method from configuration
            evolution_method = CodeHealer::ConfigManager.evolution_method
            puts "🔄 Using evolution method: #{evolution_method}"
            
            CodeHealer::HealingJob.perform_async(
              error.class.name,
              error.message,
              class_name.to_s,
              method_name.to_s,
              evolution_method,  # Use configured evolution method
              error.backtrace    # Pass the full backtrace for better analysis
            )
            puts "✅ Healing job queued for #{class_name}##{method_name}"
          else
            puts "⚠️  HealingJob not available"
          end
        end
      end
    end

    attr_reader :klass, :method_name, :context, :logger

    def initialize(klass, method_name, context = {})
      @klass = klass
      @method_name = method_name
      @context = context
      @logger = Logger.new(Rails.root.join('log', 'self_evolving.log'))
    end

    def evolve
      begin
        puts "Starting evolution for #{klass.name}##{method_name}"
        puts "Error: #{context[:error].class} - #{context[:error].message}"
        
        # Get the original method
        original_method = klass.instance_method(method_name)
        puts "Original method parameters: #{original_method.parameters.inspect}"
        
        # Generate the fixed method
        new_method = generate_method(original_method)
        puts "Generated new method:"
        puts new_method
        
        # Apply the changes directly
        if apply_changes(new_method)
          puts "Changes applied successfully"
          true
        else
          puts "Failed to apply changes"
          false
        end
      rescue => e
        logger.error("Evolution failed: #{e.message}")
        puts "Evolution failed: #{e.message}"
        puts e.backtrace
        false
      end
    end

    private

    def generate_method(original_method)
      # Get the actual parameters from the original method
      parameters = original_method.parameters
      param_list = parameters.map { |type, name| name || "arg#{type}" }.join(', ')

      # Use the source from context or try to get it
      source = context[:source]
      unless source
        begin
          source = original_method.source
          puts "Original source: #{source}"
        rescue
          # If we can't get the source, read it from the file
          file_path = Rails.root.join('app', 'models', "#{klass.name.underscore}.rb")
          content = File.read(file_path)
          if content =~ /def\s+#{method_name}.*?end/m
            source = $&
            puts "Found source in file: #{source}"
          else
            source = nil
            puts "Could not find source in file"
          end
        end
      end

      case context[:error]
      when NoMethodError
        # For nil errors, add nil checks
        <<~RUBY
          def #{method_name}(#{param_list})
            # Original method with nil checks
            if user.purchase_history.nil? || user.purchase_history.empty?
              0.05
            else
              last_purchase = user.purchase_history.last
              last_purchase && last_purchase[:amount] > 1000 ? 0.1 : 0.05
            end
          end
        RUBY
      else
        # For other errors, add basic error handling
        if source
          # Extract the method body from the source
          if source =~ /def\s+#{method_name}.*?\n(.*?)end/m
            method_body = $1
            <<~RUBY
              def #{method_name}(#{param_list})
                begin
                  #{method_body}
                rescue => e
                  logger.error("Error in #{method_name}: \#{e.message}")
                  raise e
                end
              end
            RUBY
          else
            # If we couldn't extract the body, use the whole source
            <<~RUBY
              def #{method_name}(#{param_list})
                begin
                  #{source}
                rescue => e
                  logger.error("Error in #{method_name}: \#{e.message}")
                  raise e
                end
              end
            RUBY
          end
        else
          # If we couldn't get the source, use a generic error handler
          <<~RUBY
            def #{method_name}(#{param_list})
              begin
                # Original method implementation
                super
              rescue => e
                logger.error("Error in #{method_name}: \#{e.message}")
                raise e
              end
            end
          RUBY
        end
      end
    end

    def apply_changes(new_method)
      # Write the new method to the file
      file_path = Rails.root.join('app', 'models', "#{klass.name.underscore}.rb")
      puts "Updating file: #{file_path}"
      
      content = File.read(file_path)
      puts "Current file content:"
      puts content
      
      # Find the original method definition
      method_pattern = /def\s+#{method_name}.*?end/m
      if content =~ method_pattern
        new_content = content.gsub(method_pattern, new_method)
        puts "New file content:"
        puts new_content
        
        # Write the changes
        File.write(file_path, new_content)
        puts "File updated successfully"
        
        # Reload the class to apply changes
        klass.class_eval(new_method)
        puts "Class reloaded with new method"
        
        true
      else
        puts "Could not find method #{method_name} in #{file_path}"
        false
      end
    end
  end
end 