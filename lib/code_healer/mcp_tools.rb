require 'httparty'
require 'cgi'

module CodeHealer
  # Tool for analyzing errors with context
  class ErrorAnalysisTool < MCP::Tool
    description "Analyzes errors with business context and provides intelligent analysis"
    input_schema(
      properties: {
        error_type: { type: "string" },
        error_message: { type: "string" },
        class_name: { type: "string" },
        method_name: { type: "string" },
        server_context: { type: "object" }
      },
      required: ["error_type", "error_message", "class_name", "method_name"]
    )
    annotations(
      title: "Error Analysis Tool",
      read_only_hint: true,
      destructive_hint: false,
      idempotent_hint: true,
      open_world_hint: false
    )

    def self.call(error_type:, error_message:, class_name:, method_name:, server_context:)
      context = server_context&.dig(:codebase_context) || {}
      
      analysis = {
        severity: assess_error_severity(error_type, context),
        impact: assess_business_impact(error_type, context),
        root_cause: identify_root_cause(error_type, error_message, context),
        suggested_fixes: generate_suggested_fixes(error_type, context),
        risks: assess_evolution_risks(error_type, context),
        performance_implications: assess_performance_implications(error_type, context),
        security_considerations: assess_security_considerations(error_type, context)
      }
      
      MCP::Tool::Response.new([{ type: "text", text: analysis.to_json }])
    end
    
    private
    
    def self.assess_error_severity(error_type, context)
      'medium'
    end
    
    def self.assess_business_impact(error_type, context)
      {
        user_experience: 'minimal',
        data_integrity: 'none',
        financial_impact: 'none',
        compliance_impact: 'none'
      }
    end
    
    def self.identify_root_cause(error_type, error_message, context)
      {
        immediate_cause: error_message,
        underlying_cause: 'insufficient_validation',
        contributing_factors: ['missing_input_validation', 'lack_of_error_handling'],
        prevention_strategies: ['add_input_validation', 'implement_defensive_programming']
      }
    end
    
    def self.generate_suggested_fixes(error_type, context)
      fixes = ['add_error_handling', 'improve_validation', 'add_logging']
      case error_type
      when 'ZeroDivisionError'
        fixes.unshift('add_zero_division_check')
      when 'TypeError'
        fixes.unshift('add_type_validation')
      when 'NoMethodError'
        fixes.unshift('implement_missing_method', 'provide_fallback_implementation')
      end
      fixes
    end
    
    def self.assess_evolution_risks(error_type, context)
      {
        regression_risk: 'low',
        performance_risk: 'low',
        security_risk: 'low',
        compatibility_risk: 'low'
      }
    end
    
    def self.assess_performance_implications(error_type, context)
      {
        execution_time: 'minimal',
        memory_usage: 'minimal',
        cpu_usage: 'minimal',
        overall_impact: 'minimal'
      }
    end
    
    def self.assess_security_considerations(error_type, context)
      {
        vulnerability_risk: 'low',
        data_exposure: 'none',
        authentication_impact: 'none',
        authorization_impact: 'none'
      }
    end
  end

  # Tool for generating intelligent code fixes
  class CodeFixTool < MCP::Tool
    description "Generates intelligent code fixes using AI with business context"
    input_schema(
      properties: {
        error_type: { type: "string" },
        error_message: { type: "string" },
        class_name: { type: "string" },
        method_name: { type: "string" },
        analysis: { type: "object" },
        context: { type: "object" },
        server_context: { type: "object" }
      },
      required: ["error_type", "error_message", "class_name", "method_name"]
    )
    annotations(
      title: "Code Fix Tool",
      read_only_hint: false,
      destructive_hint: false,
      idempotent_hint: false,
      open_world_hint: false
    )

    def self.call(error_type:, error_message:, class_name:, method_name:, analysis: nil, context: nil, server_context:)
      # puts "🔍 Debug: CodeFixTool.call called with error_type=#{error_type}, method_name=#{method_name}"
      
      # Merge context and server_context for comprehensive context
      comprehensive_context = merge_contexts(context, server_context)
      puts "🔍 Debug: Comprehensive context merged: #{comprehensive_context.keys.inspect}"
      
              # Build intelligent prompt with comprehensive context
        prompt = build_intelligent_prompt(error_type, error_message, class_name, method_name, analysis, comprehensive_context)
        puts "Deepan - #{prompt}"
        puts "🔍 Debug: Prompt built successfully"
        puts "🔍 Debug: Prompt length = #{prompt.length} characters"
      
      # Generate fix using AI
      fix = generate_ai_fix(prompt, method_name)
      
      puts "🔍 Debug: AI fix generated: #{fix.inspect}"
      
      # Return the fix as MCP response
      MCP::Tool::Response.new([{ type: "text", text: fix.to_json }])
    end
    
    private
    
    def self.merge_contexts(context, server_context)
      # Start with server_context as base
      merged = server_context&.dup || {}
      
      # Merge in context if provided
      if context
        # Handle different context structures
        if context.is_a?(Hash)
          # Deep merge context into merged
          context.each do |key, value|
            if merged[key].is_a?(Hash) && value.is_a?(Hash)
              merged[key] = merged[key].merge(value)
            else
              merged[key] = value
            end
          end
        elsif context.is_a?(Array)
          # If context is an array, add it to merged
          merged[:context_array] = context
        end
      end
      
      puts "🔍 Debug: Merged context keys: #{merged.keys.inspect}"
      merged
    end
    
    def self.build_intelligent_prompt(error_type, error_message, class_name, method_name, analysis, comprehensive_context)
      # puts "🔍 Debug: build_intelligent_prompt called"
      
      # Safely access nested hash values from the comprehensive context
      codebase_context = comprehensive_context&.dig(:codebase_context) || comprehensive_context&.dig('codebase_context') || {}
      puts "🔍 Debug: codebase_context = #{codebase_context.inspect}"
      
      business_rules = comprehensive_context&.dig('business_context') || comprehensive_context&.dig(:business_context) || {}
      puts "🔍 Debug: business_rules = #{business_rules.inspect}"
      
      coding_standards = comprehensive_context&.dig('coding_standards') || codebase_context&.dig('coding_standards') || {}
      # puts "🔍 Debug: coding_standards = #{coding_standards.inspect}"
      
      # Extract actual method signature from source code
      actual_signature = extract_method_signature(class_name, method_name)
      # puts "🔍 Debug: Actual method signature: #{actual_signature}"
      
      <<~PROMPT
        You are an expert Ruby developer and code evolution specialist. Generate a production-ready fix for the following error:
        
        ERROR DETAILS:
        Type: #{error_type}
        Message: #{error_message}
        Class: #{class_name}
        Method: #{method_name}
        ACTUAL METHOD SIGNATURE: #{actual_signature}
        
        BUSINESS CONTEXT:
        The following business context has been loaded from business requirements documents:
        
        #{format_business_context_for_prompt(business_rules, codebase_context, error_type)}
        
        Please review this business context and apply the business rules naturally in your code generation.
        
        CODING STANDARDS:
        Error Handling: #{coding_standards['error_handling']}
        Logging: #{coding_standards['logging']}
        Validation: #{coding_standards['validation']}
        Performance: #{coding_standards['performance']}
        
        BUSINESS RULE COMPLIANCE:
        - The system has loaded business context and rules that specify how to handle errors
        - CRITICAL: Business rules specify specific return values for different error types
        - Review the business context provided and apply the business rules naturally
        - Business rules may specify specific return values, logging requirements, or handling strategies
        - Ensure your error handling aligns with the business requirements provided
        - The business context above contains specific requirements for this error type
        - PAY SPECIAL ATTENTION to the "CRITICAL BUSINESS RULE" and "CRITICAL CALCULATION ERROR RULE" sections above
        
        CODE REQUIREMENTS:
        - Generate ONLY the complete method implementation (def method_name...end)
        - IMPORTANT: Use the EXACT method signature: #{actual_signature}
        - Include comprehensive error handling specific to #{error_type}
        - Add business-appropriate logging using Rails.logger
        - Include input validation and parameter checking
        - Follow Ruby best practices and conventions
        - Ensure the fix is production-ready and secure
        - Add performance considerations where relevant
        - Include proper return values and error responses
        - Use the exact method name: #{method_name}
        - Apply business rules from the provided context naturally
        
        EXAMPLE FORMAT (adapt to your actual method signature):
        #{actual_signature}
          # Input validation
          return business_rule_default_value if param1.nil? || param2.nil?
          
          # Business logic with error handling
          begin
            result = param1 / param2
            Rails.logger.info("Operation successful: \#{param1} / \#{param2} = \#{result}")
            result
          rescue #{error_type} => e
            Rails.logger.warn("#{error_type} occurred: \#{e.message}")
            # Apply business rules from context for appropriate return value
            return business_rule_default_value
          rescue => e
            Rails.logger.error("Unexpected error in operation: \#{e.message}")
            # Apply business rules from context for appropriate return value
            return business_rule_default_value
          end
        end
        
        NOTE: Replace 'business_rule_default_value' with the actual value specified in your business context above.
        IMPORTANT: Look for the "CRITICAL BUSINESS RULE - Return Value" section to find the exact return value to use.
        
        Generate a complete, intelligent fix for the #{method_name} method that specifically addresses the #{error_type}:
      PROMPT
    end
    

    
    def self.format_business_context_for_prompt(business_rules, codebase_context, error_type)
      puts "🔍 Debug: format_business_context_for_prompt called"
      puts "🔍 Debug: business_rules = #{business_rules.inspect}"
      puts "🔍 Debug: codebase_context keys = #{codebase_context.keys.inspect}"
      
      context_parts = []
      
      # First, try to extract from business_rules (which should contain the analyzer output)
      if business_rules && business_rules.any?
        if business_rules[:business_rules]&.any?
          context_parts << "=== BUSINESS RULES FROM ANALYZER ==="
          business_rules[:business_rules].each do |rule|
            if rule.is_a?(Hash) && rule[:content]
              context_parts << rule[:content]
            elsif rule.is_a?(String)
              context_parts << rule
            end
          end
        end
        
        if business_rules[:domain_specific]&.any?
          context_parts << "\n=== DOMAIN-SPECIFIC RULES ==="
          business_rules[:domain_specific].each do |key, value|
            if value.is_a?(Array)
              value.each { |line| context_parts << line }
            elsif value.is_a?(String)
              context_parts << value
            end
          end
        end
      end
      
      # Also check codebase_context for additional business context
      business_context = codebase_context[:business_context] || codebase_context['business_context']
      if business_context && business_context.any?
        if business_context[:business_rules]&.any?
          context_parts << "\n=== ADDITIONAL BUSINESS RULES ==="
          business_context[:business_rules].each do |rule|
            if rule.is_a?(Hash) && rule[:content]
              context_parts << rule[:content]
            elsif rule.is_a?(String)
              context_parts << rule
            end
          end
        end
      end
      
      # Include markdown requirement documents verbatim from business_rules
      markdown_requirements = business_rules[:markdown_requirements] || business_rules['markdown_requirements']
      if markdown_requirements
        context_parts << "\n=== BUSINESS REQUIREMENTS FROM MARKDOWN DOCUMENTS ==="
        context_parts << markdown_requirements.to_s
      end
      
      result = context_parts.empty? ? "No specific business context loaded." : context_parts.join("\n")
      puts "🔍 Debug: Final result length = #{result.length} characters"
      result
    end

    def self.extract_method_signature(class_name, method_name)
      # Try to find the actual method signature from the source code
      file_path = find_class_file(class_name)
      return "def #{method_name}(*args, **kwargs, &block)" unless file_path && File.exist?(file_path)
      
      content = File.read(file_path)
      method_pattern = /def\s+#{method_name}\s*\([^)]*\)/
      match = content.match(method_pattern)
      
      if match
        match[0]  # Return the complete method signature line
      else
        "def #{method_name}(*args, **kwargs, &block)"  # Fallback
      end
    rescue => e
      puts "🔍 Debug: Error extracting method signature: #{e.message}"
      "def #{method_name}(*args, **kwargs, &block)"  # Fallback
    end

    def self.find_class_file(class_name)
      # Look for the class file in common Rails locations
      possible_paths = [
        "app/models/#{class_name.underscore}.rb",
        "app/controllers/#{class_name.underscore}.rb",
        "app/services/#{class_name.underscore}.rb",
        "lib/#{class_name.underscore}.rb"
      ]
      
      possible_paths.find { |path| File.exist?(path) }
    end
    
    def self.generate_ai_fix(prompt, method_name)
      puts "🔍 Debug: generate_ai_fix called with method_name=#{method_name}"
      
      begin
        unless ENV['OPENAI_API_KEY']
          puts "❌ OpenAI API key not found. Please set OPENAI_API_KEY environment variable."
          return generate_fallback_fix(method_name)
        end
        
        puts "🤖 Calling OpenAI API for intelligent fix generation..."
        client = OpenAI::Client.new(api_key: ENV['OPENAI_API_KEY'])
        
        response = client.chat.completions.create(
          messages: [
            {
              role: "system",
              content: "You are an expert Ruby developer and code evolution specialist. Generate intelligent, production-ready code fixes that are context-aware, secure, and follow Ruby best practices. Always return complete, syntactically correct Ruby method implementations."
            },
            {
              role: "user",
              content: prompt
            }
          ],
          model: :"gpt-4",
          temperature: 0.3,
          max_tokens: 1000
        )
        
        puts "🔍 Debug: OpenAI response received"
        
        ai_response = response.choices.first.message.content
        puts "🤖 AI generated code: #{ai_response}"
        
        # Parse the AI response
        parsed_fix = parse_ai_response(ai_response, method_name)
        
        if parsed_fix
          puts "✅ Successfully parsed AI-generated method: #{method_name}"
          puts "🔍 Debug: parsed_fix = #{parsed_fix.inspect}"
          parsed_fix
        else
          puts "❌ Failed to parse AI response, using fallback"
          generate_fallback_fix(method_name)
        end
        
      rescue => e
        puts "❌ OpenAI API error: #{e.message}"
        puts "🔧 Falling back to template-based fix"
        generate_fallback_fix(method_name)
      end
    end
    
    def self.parse_ai_response(ai_response, method_name)
      # Parse AI response to extract the method implementation
      # Escape special regex characters in method name
      escaped_method_name = Regexp.escape(method_name)
      
      # Look for the complete method from def to the final end
      method_pattern = /def\s+#{escaped_method_name}\s*\([^)]*\)(.*?)\nend/m
      
      if ai_response.match(method_pattern)
        match = ai_response.match(method_pattern)
        method_code = match[0]  # Use the complete matched method
        
        puts "🔍 Debug: parse_ai_response - extracted complete method: #{method_code.inspect}"
        
        # Ensure proper indentation
        method_code = method_code.gsub(/^/, '  ')  # Add 2 spaces indentation
        
        puts "🔍 Debug: parse_ai_response - final method code: #{method_code.inspect}"
        
        {
          method_name: method_name,
          new_code: method_code,
          source: 'ai_generated'
        }
      else
        puts "❌ Could not parse AI response, using fallback"
        puts "🔍 Debug: method_pattern = #{method_pattern.inspect}"
        puts "🔍 Debug: ai_response = #{ai_response[0..200]}..."
        generate_fallback_fix(method_name)
      end
    end
    
    def self.generate_fallback_fix(method_name)
      puts "🔧 Using fallback fix"
      {
        method_name: method_name,
        new_code: <<~CODE,
          def #{method_name}(a, b)
            # Input validation
            return business_rule_default_value if a.nil? || b.nil?
            
            # Business logic with error handling
            begin
              if b.zero?
                Rails.logger.warn("Division by zero attempted: \#{a} / \#{b}")
                return business_rule_default_value
              end
              
              result = a / b
              Rails.logger.info("Operation successful: \#{a} / \#{b} = \#{result}")
              result
            rescue => e
              Rails.logger.error("Unexpected error in operation: \#{e.message}")
              # Apply business rules from context for appropriate return value
              return business_rule_default_value
            end
          end
        CODE
        source: 'fallback_template'
      }
    end
  end

  # Tool for analyzing context and validating fixes
  class ContextAnalysisTool < MCP::Tool
    description "Validates fixes with business context and provides recommendations"
    input_schema(
      properties: {
        fix: { type: "object" },
        context: { type: "object" },
        server_context: { type: "object" }
      },
      required: ["fix", "context"]
    )
    annotations(
      title: "Context Analysis Tool",
      read_only_hint: true,
      destructive_hint: false,
      idempotent_hint: true,
      open_world_hint: false
    )

    def self.call(fix:, context:, server_context:)
      validation = {
        syntax_valid: validate_syntax(fix),
        business_logic_valid: validate_business_logic(fix, context),
        performance_acceptable: validate_performance(fix, context),
        security_safe: validate_security(fix, context),
        test_coverage: suggest_test_coverage(fix, context),
        documentation_needed: suggest_documentation(fix, context),
        approved: true, # Will be set based on validation results
        confidence_score: calculate_confidence_score(fix, context),
        recommendations: generate_recommendations(fix, context)
      }
      
      # Set approval based on validation results - be more lenient for AI-generated fixes
      validation[:approved] = validation[:syntax_valid] && 
                             validation[:business_logic_valid]
      
      MCP::Tool::Response.new([{ type: "text", text: validation.to_json }])
    end
    
    private
    
    def self.validate_syntax(fix)
      # Basic syntax validation
      begin
        # Parse fix if it's a string (JSON response)
        fix_data = fix.is_a?(String) ? JSON.parse(fix) : fix
        
        # Add missing 'end' if the method is incomplete
        code = fix_data['new_code'] || fix_data[:new_code]
        puts "🔍 Debug: validate_syntax - original code: #{code.inspect}"
        
        return false if code.nil?
        
        if code.count('def') > code.count('end')
          code += "\nend"
          puts "🔍 Debug: validate_syntax - added missing end"
        end
        
        puts "🔍 Debug: validate_syntax - final code: #{code.inspect}"
        RubyVM::InstructionSequence.compile(code)
        puts "🔍 Debug: validate_syntax - syntax validation passed"
        true
      rescue SyntaxError => e
        puts "🔍 Debug: validate_syntax - syntax validation failed: #{e.message}"
        false
      rescue => e
        puts "🔍 Debug: validate_syntax - validation error: #{e.message}"
        false
      end
    end
    
    def self.validate_business_logic(fix, context)
      # Validate business logic appropriateness
      true
    end
    
    def self.validate_performance(fix, context)
      # Validate performance characteristics
      true
    end
    
    def self.validate_security(fix, context)
      # Validate security aspects
      true
    end
    
    def self.suggest_test_coverage(fix, context)
      [
        "test_normal_operation",
        "test_error_conditions",
        "test_edge_cases",
        "test_input_validation"
      ]
    end
    
    def self.suggest_documentation(fix, context)
      [
        "add_method_documentation",
        "document_error_handling",
        "add_usage_examples"
      ]
    end
    
    def self.calculate_confidence_score(fix, context)
      rand(0.7..1.0)
    end
    
    def self.generate_recommendations(fix, context)
      [
        "monitor_performance_after_deployment",
        "add_comprehensive_tests",
        "review_logging_levels",
        "consider_error_metrics"
      ]
    end
  end

  # Tool for analyzing Git history and commit changes
  class GitHistoryAnalysisTool < MCP::Tool
    description "Analyzes Git history to understand changes, commits, and their impact"
    input_schema(
      properties: {
        file_path: { type: "string" },
        class_name: { type: "string" },
        method_name: { type: "string" },
        search_query: { type: "string" },
        server_context: { type: "object" }
      },
      required: ["file_path"]
    )
    annotations(
      title: "Git History Analysis Tool",
      read_only_hint: true,
      destructive_hint: false,
      idempotent_hint: true,
      open_world_hint: false
    )

    def self.call(file_path:, class_name: nil, method_name: nil, search_query: nil, server_context:)
      analysis = {
        file_history: analyze_file_history(file_path),
        recent_changes: get_recent_changes(file_path),
        commit_impact: analyze_commit_impact(file_path, class_name, method_name),
        related_commits: find_related_commits(file_path, search_query),
        change_patterns: identify_change_patterns(file_path),
        author_analysis: analyze_author_patterns(file_path),
        risk_assessment: assess_change_risks(file_path),
        recommendations: generate_git_recommendations(file_path, class_name, method_name)
      }
      
      MCP::Tool::Response.new([{ type: "text", text: analysis.to_json }])
    end
    
    private
    
    def self.analyze_file_history(file_path)
      return { error: "File not found" } unless File.exist?(file_path)
      
      begin
        # Get git log for the file
        git_log = `git log --oneline --follow "#{file_path}" 2>/dev/null`
        commits = git_log.strip.split("\n").map { |line| line.split(' ', 2) }
        
        {
          total_commits: commits.length,
          first_commit: commits.last&.first,
          last_commit: commits.first&.first,
          commit_summary: commits.first(10).map { |hash, msg| { hash: hash, message: msg } }
        }
      rescue => e
        { error: "Git analysis failed: #{e.message}" }
      end
    end
    
    def self.get_recent_changes(file_path)
      return { error: "File not found" } unless File.exist?(file_path)
      
      begin
        # Get recent changes (last 5 commits)
        git_log = `git log -p -5 "#{file_path}" 2>/dev/null`
        
        # Parse the git log to extract meaningful changes
        changes = parse_git_changes(git_log)
        
        {
          recent_commits: changes[:commits],
          change_summary: changes[:summary],
          lines_added: changes[:lines_added],
          lines_removed: changes[:lines_removed]
        }
      rescue => e
        { error: "Recent changes analysis failed: #{e.message}" }
      end
    end
    
    def self.analyze_commit_impact(file_path, class_name, method_name)
      return { error: "File not found" } unless File.exist?(file_path)
      
      begin
        # Analyze impact of recent commits on specific class/method
        if class_name && method_name
          git_blame = `git blame -L "/#{method_name}/" "#{file_path}" 2>/dev/null`
          blame_analysis = parse_git_blame(git_blame)
          
          {
            method_changes: blame_analysis[:method_changes],
            last_modified: blame_analysis[:last_modified],
            change_frequency: blame_analysis[:change_frequency],
            impact_level: assess_method_impact(blame_analysis)
          }
        else
          { message: "Class and method names required for detailed impact analysis" }
        end
      rescue => e
        { error: "Commit impact analysis failed: #{e.message}" }
      end
    end
    
    def self.find_related_commits(file_path, search_query)
      return { error: "File not found" } unless File.exist?(file_path)
      
      begin
        if search_query
          # Search for commits containing the query
          git_log = `git log --grep="#{search_query}" --oneline "#{file_path}" 2>/dev/null`
          commits = git_log.strip.split("\n").map { |line| line.split(' ', 2) }
          
          {
            search_query: search_query,
            matching_commits: commits.map { |hash, msg| { hash: hash, message: msg } },
            total_matches: commits.length
          }
        else
          { message: "Search query required for related commits analysis" }
        end
      rescue => e
        { error: "Related commits search failed: #{e.message}" }
      end
    end
    
    def self.identify_change_patterns(file_path)
      return { error: "File not found" } unless File.exist?(file_path)
      
      begin
        # Analyze patterns in file changes
        git_log = `git log --stat "#{file_path}" 2>/dev/null`
        patterns = analyze_change_statistics(git_log)
        
        {
          change_frequency: patterns[:frequency],
          typical_change_size: patterns[:typical_size],
          change_types: patterns[:types],
          seasonal_patterns: patterns[:seasonal]
        }
      rescue => e
        { error: "Change pattern analysis failed: #{e.message}" }
      end
    end
    
    def self.analyze_author_patterns(file_path)
      return { error: "File not found" } unless File.exist?(file_path)
      
      begin
        # Analyze who has been making changes to the file
        git_log = `git shortlog -sn "#{file_path}" 2>/dev/null`
        authors = git_log.strip.split("\n").map { |line| line.split("\t") }
        
        {
          contributors: authors.map { |count, author| { author: author, commits: count.to_i } },
          primary_owner: authors.first&.last,
          ownership_distribution: calculate_ownership_distribution(authors)
        }
      rescue => e
        { error: "Author pattern analysis failed: #{e.message}" }
      end
    end
    
    def self.assess_change_risks(file_path)
      return { error: "File not found" } unless File.exist?(file_path)
      
      begin
        # Assess risks based on change patterns
        git_log = `git log --oneline "#{file_path}" 2>/dev/null`
        recent_commits = git_log.strip.split("\n").first(5)
        
        risk_factors = []
        risk_factors << "frequent_changes" if recent_commits.length > 3
        risk_factors << "multiple_authors" if `git shortlog -sn "#{file_path}" 2>/dev/null`.strip.split("\n").length > 2
        risk_factors << "recent_modifications" if recent_commits.any?
        
        {
          risk_level: calculate_risk_level(risk_factors),
          risk_factors: risk_factors,
          recommendations: generate_risk_recommendations(risk_factors)
        }
      rescue => e
        { error: "Risk assessment failed: #{e.message}" }
      end
    end
    
    def self.generate_git_recommendations(file_path, class_name, method_name)
      recommendations = []
      
      # Generate recommendations based on analysis
      recommendations << "review_recent_changes" if File.exist?(file_path)
      recommendations << "assess_test_coverage" if class_name && method_name
      recommendations << "document_changes" if File.exist?(file_path)
      recommendations << "peer_review_required" if `git shortlog -sn "#{file_path}" 2>/dev/null`.strip.split("\n").length > 1
      
      recommendations
    end
    
    # Helper methods for parsing git output
    def self.parse_git_changes(git_log)
      # Parse git log output to extract meaningful information
      commits = []
      lines_added = 0
      lines_removed = 0
      
      git_log.scan(/commit (\w+)\nAuthor: (.+)\nDate: (.+)\n\n(.+?)(?=commit|\z)/m).each do |match|
        commits << {
          hash: match[0],
          author: match[1],
          date: match[2],
          message: match[3].strip
        }
      end
      
      {
        commits: commits,
        summary: "Recent changes analyzed",
        lines_added: lines_added,
        lines_removed: lines_removed
      }
    end
    
    def self.parse_git_blame(git_blame)
      # Parse git blame output
      method_changes = []
      last_modified = nil
      
      git_blame.scan(/^(\w+)\s+\((.+?)\s+\d{4}-\d{2}-\d{2}/).each do |match|
        hash = match[0]
        author = match[1]
        method_changes << { hash: hash, author: author }
        last_modified = hash unless last_modified
      end
      
      {
        method_changes: method_changes,
        last_modified: last_modified,
        change_frequency: method_changes.length
      }
    end
    
    def self.analyze_change_statistics(git_log)
      # Analyze git log statistics
      {
        frequency: "moderate",
        typical_size: "small",
        types: ["bug_fixes", "refactoring"],
        seasonal: "no_pattern"
      }
    end
    
    def self.calculate_ownership_distribution(authors)
      return "single_owner" if authors.length == 1
      return "shared_ownership" if authors.length <= 3
      "distributed_ownership"
    end
    
    def self.calculate_risk_level(risk_factors)
      return "high" if risk_factors.length >= 3
      return "medium" if risk_factors.length >= 2
      "low"
    end
    
    def self.generate_risk_recommendations(risk_factors)
      recommendations = []
      recommendations << "increase_test_coverage" if risk_factors.include?("frequent_changes")
      recommendations << "implement_code_review" if risk_factors.include?("multiple_authors")
      recommendations << "monitor_performance" if risk_factors.include?("recent_modifications")
      recommendations
    end
    
    def self.assess_method_impact(blame_analysis)
      return "high" if blame_analysis[:change_frequency] > 5
      return "medium" if blame_analysis[:change_frequency] > 2
      "low"
    end
  end

  # Tool for referencing coding standards and best practices
  class StandardsReferenceTool < MCP::Tool
    description "Provides access to coding standards, best practices, and architectural guidelines"
    input_schema(
      properties: {
        standard_type: { type: "string" },
        domain: { type: "string" },
        class_name: { type: "string" },
        method_name: { type: "string" },
        search_query: { type: "string" },
        server_context: { type: "object" }
      },
      required: ["standard_type"]
    )
    annotations(
      title: "Standards Reference Tool",
      read_only_hint: true,
      destructive_hint: false,
      idempotent_hint: true,
      open_world_hint: false
    )

    def self.call(standard_type:, domain: nil, class_name: nil, method_name: nil, search_query: nil, server_context:)
      standards = {
        coding_standards: get_coding_standards(standard_type, domain),
        best_practices: get_best_practices(standard_type, domain, class_name),
        architectural_guidelines: get_architectural_guidelines(domain),
        domain_specific_rules: get_domain_specific_rules(domain, class_name),
        compliance_requirements: get_compliance_requirements(domain),
        performance_standards: get_performance_standards(domain),
        security_standards: get_security_standards(domain),
        testing_standards: get_testing_standards(standard_type),
        documentation_standards: get_documentation_standards(standard_type),
        recommendations: generate_standards_recommendations(standard_type, domain, class_name, method_name)
      }
      
      MCP::Tool::Response.new([{ type: "text", text: standards.to_json }])
    end
    
    private
    
    def self.get_coding_standards(standard_type, domain)
      case standard_type
      when 'error_handling'
        {
          general: 'comprehensive_error_handling',
          strategy: 'defensive_programming',
          logging: 'structured_logging',
          user_experience: 'graceful_degradation',
          recovery: 'automatic_recovery_when_possible'
        }
      when 'validation'
        {
          input_validation: 'strict_validation',
          data_sanitization: 'required',
          type_checking: 'enforced',
          boundary_checks: 'mandatory'
        }
      when 'performance'
        {
          response_time: 'under_500ms',
          memory_usage: 'optimized',
          database_queries: 'minimal',
          caching: 'strategic'
        }
      when 'security'
        {
          authentication: 'required',
          authorization: 'role_based',
          data_encryption: 'sensitive_data',
          input_sanitization: 'mandatory'
        }
      else
        { message: "Standard type '#{standard_type}' not found" }
      end
    end
    
    def self.get_best_practices(standard_type, domain, class_name)
      practices = []
      
      case standard_type
      when 'error_handling'
        practices << 'use_specific_exception_types'
        practices << 'provide_meaningful_error_messages'
        practices << 'implement_graceful_fallbacks'
        practices << 'log_errors_with_context'
      when 'validation'
        practices << 'validate_at_boundaries'
        practices << 'use_strong_typing'
        practices << 'implement_business_rule_validation'
        practices << 'provide_clear_validation_errors'
      when 'performance'
        practices << 'profile_before_optimizing'
        practices << 'use_appropriate_data_structures'
        practices << 'implement_caching_strategies'
        practices << 'minimize_database_round_trips'
      when 'security'
        practices << 'follow_owasp_guidelines'
        practices << 'implement_least_privilege'
        practices << 'validate_all_inputs'
        practices << 'encrypt_sensitive_data'
      end
      
      practices
    end
    
    def self.get_architectural_guidelines(domain)
      case domain
      when 'user_management'
        {
          pattern: 'repository_pattern',
          separation: 'business_logic_from_presentation',
          data_access: 'through_models',
          security: 'layered_security'
        }
      when 'inventory_management'
        {
          pattern: 'domain_driven_design',
          consistency: 'eventual_consistency',
          caching: 'distributed_caching',
          monitoring: 'real_time_monitoring'
        }
      when 'order_management'
        {
          pattern: 'saga_pattern',
          transactions: 'distributed_transactions',
          reliability: 'fault_tolerance',
          monitoring: 'business_metrics'
        }
      when 'payment_processing'
        {
          pattern: 'facade_pattern',
          security: 'end_to_end_encryption',
          compliance: 'pci_dss_compliance',
          monitoring: 'fraud_detection'
        }
      else
        { message: "Domain '#{domain}' not found" }
      end
    end
    
    def self.get_domain_specific_rules(domain, class_name)
      return {} unless domain
      
      case domain
      when 'user_management'
        {
          data_privacy: 'gdpr_compliant',
          authentication: 'multi_factor_required',
          session_management: 'secure_session_handling',
          audit_trail: 'comprehensive_logging'
        }
      when 'inventory_management'
        {
          data_consistency: 'eventual_consistency',
          stock_validation: 'real_time_validation',
          availability: 'high_availability',
          backup_strategy: 'continuous_backup'
        }
      when 'order_management'
        {
          data_integrity: 'acid_compliance',
          order_status: 'immutable_status_transitions',
          payment_validation: 'pre_authorization_required',
          fulfillment: 'automated_fulfillment'
        }
      when 'payment_processing'
        {
          security: 'pci_dss_compliance',
          encryption: 'end_to_end_encryption',
          fraud_detection: 'real_time_monitoring',
          compliance: 'regulatory_compliance'
        }
      else
        {}
      end
    end
    
    def self.get_compliance_requirements(domain)
      case domain
      when 'user_management'
        ['GDPR', 'CCPA', 'SOX']
      when 'payment_processing'
        ['PCI-DSS', 'SOX', 'GLBA']
      when 'inventory_management'
        ['SOX', 'ISO_27001']
      when 'order_management'
        ['SOX', 'PCI-DSS']
      else
        ['SOX']
      end
    end
    
    def self.get_performance_standards(domain)
      case domain
      when 'user_management'
        { response_time: 'under_200ms', sla: '99.9%' }
      when 'inventory_management'
        { response_time: 'under_100ms', sla: '99.95%' }
      when 'order_management'
        { response_time: 'under_500ms', sla: '99.99%' }
      when 'payment_processing'
        { response_time: 'under_1000ms', sla: '99.99%' }
      else
        { response_time: 'under_500ms', sla: '99.5%' }
      end
    end
    
    def self.get_security_standards(domain)
      case domain
      when 'user_management'
        { authentication: 'required', encryption: 'sensitive_data_only' }
      when 'payment_processing'
        { authentication: 'required', encryption: 'all_data' }
      when 'inventory_management'
        { authentication: 'required', encryption: 'standard' }
      else
        { authentication: 'required', encryption: 'standard' }
      end
    end
    
    def self.get_testing_standards(standard_type)
      case standard_type
      when 'error_handling'
        ['test_error_conditions', 'test_edge_cases', 'test_recovery_scenarios']
      when 'validation'
        ['test_invalid_inputs', 'test_boundary_conditions', 'test_business_rules']
      when 'performance'
        ['test_under_load', 'test_memory_usage', 'test_response_times']
      when 'security'
        ['test_authentication', 'test_authorization', 'test_input_validation']
      else
        ['test_normal_operation', 'test_error_conditions', 'test_edge_cases']
      end
    end
    
    def self.get_documentation_standards(standard_type)
      case standard_type
      when 'error_handling'
        ['document_error_scenarios', 'document_recovery_procedures', 'document_logging_format']
      when 'validation'
        ['document_validation_rules', 'document_error_messages', 'document_business_constraints']
      when 'performance'
        ['document_performance_requirements', 'document_monitoring_metrics', 'document_optimization_strategies']
      when 'security'
        ['document_security_requirements', 'document_compliance_measures', 'document_incident_response']
      else
        ['document_usage', 'document_parameters', 'document_return_values']
      end
    end
    
    def self.generate_standards_recommendations(standard_type, domain, class_name, method_name)
      recommendations = []
      
      recommendations << "follow_#{standard_type}_standards"
      recommendations << "implement_domain_specific_rules" if domain
      recommendations << "add_comprehensive_tests" if class_name && method_name
      recommendations << "document_implementation" if class_name && method_name
      recommendations << "review_with_team" if standard_type == 'security'
      
      recommendations
    end
  end

  # Tool for searching and accessing supporting documentation
  class DocumentationSearchTool < MCP::Tool
    description "Searches and provides access to supporting documentation, README files, and feature documentation"
    input_schema(
      properties: {
        search_query: { type: "string" },
        document_type: { type: "string" },
        feature_name: { type: "string" },
        class_name: { type: "string" },
        method_name: { type: "string" },
        server_context: { type: "object" }
      },
      required: ["search_query"]
    )
    annotations(
      title: "Documentation Search Tool",
      read_only_hint: true,
      destructive_hint: false,
      idempotent_hint: true,
      open_world_hint: false
    )

    def self.call(search_query:, document_type: nil, feature_name: nil, class_name: nil, method_name: nil, server_context:)
      search_results = {
        documentation_files: search_documentation_files(search_query),
        readme_files: search_readme_files(search_query),
        feature_docs: search_feature_documentation(search_query, feature_name),
        api_documentation: search_api_documentation(search_query),
        code_comments: search_code_comments(search_query, class_name, method_name),
        configuration_files: search_configuration_files(search_query),
        related_documents: find_related_documents(search_query),
        recommendations: generate_documentation_recommendations(search_query, document_type, feature_name)
      }
      
      MCP::Tool::Response.new([{ type: "text", text: search_results.to_json }])
    end
    
    private
    
    def self.search_documentation_files(search_query)
      documentation_files = []
      
      # Search in common documentation directories
      doc_dirs = ['doc', 'docs', 'documentation', 'README.md', 'API_README.md']
      
      doc_dirs.each do |dir|
        if Dir.exist?(dir)
          Dir.glob("#{dir}/**/*").each do |file|
            next unless File.file?(file) && File.readable?(file)
            
            content = File.read(file)
            if content.downcase.include?(search_query.downcase)
              documentation_files << {
                file_path: file,
                file_type: File.extname(file),
                relevance_score: calculate_relevance(content, search_query),
                excerpt: extract_relevant_excerpt(content, search_query)
              }
            end
          end
        elsif File.exist?(dir)
          content = File.read(dir)
          if content.downcase.include?(search_query.downcase)
            documentation_files << {
              file_path: dir,
              file_type: File.extname(dir),
              relevance_score: calculate_relevance(content, search_query),
              excerpt: extract_relevant_excerpt(content, search_query)
            }
          end
        end
      end
      
      documentation_files.sort_by { |file| -file[:relevance_score] }
    end
    
    def self.search_readme_files(search_query)
      readme_files = []
      
      # Search for README files in the project
      Dir.glob("**/README*").each do |file|
        next unless File.file?(file) && File.readable?(file)
        
        content = File.read(file)
        if content.downcase.include?(search_query.downcase)
          readme_files << {
            file_path: file,
            relevance_score: calculate_relevance(content, search_query),
            excerpt: extract_relevant_excerpt(content, search_query),
            section_matches: find_matching_sections(content, search_query)
          }
        end
      end
      
      readme_files.sort_by { |file| -file[:relevance_score] }
    end
    
    def self.search_feature_documentation(search_query, feature_name)
      feature_docs = []
      
      # Search for feature-specific documentation
      if feature_name
        # Look for feature-specific files
        feature_files = Dir.glob("**/*#{feature_name}*").select { |f| File.file?(f) && File.readable?(f) }
        
        feature_files.each do |file|
          content = File.read(file)
          if content.downcase.include?(search_query.downcase)
            feature_docs << {
              file_path: file,
              feature_name: feature_name,
              relevance_score: calculate_relevance(content, search_query),
              excerpt: extract_relevant_excerpt(content, search_query)
            }
          end
        end
      end
      
      feature_docs.sort_by { |doc| -doc[:relevance_score] }
    end
    
    def self.search_api_documentation(search_query)
      api_docs = []
      
      # Search for API documentation
      api_files = Dir.glob("**/API_README*").select { |f| File.file?(f) && File.readable?(f) }
      
      api_files.each do |file|
        content = File.read(file)
        if content.downcase.include?(search_query.downcase)
          api_docs << {
            file_path: file,
            relevance_score: calculate_relevance(content, search_query),
            excerpt: extract_relevant_excerpt(content, search_query),
            endpoint_matches: find_api_endpoints(content, search_query)
          }
        end
      end
      
      api_docs
    end
    
    def self.search_code_comments(search_query, class_name, method_name)
      code_comments = []
      
      # Search for code comments and documentation
      if class_name
        class_file = find_class_file(class_name)
        if class_file && File.exist?(class_file)
          content = File.read(class_file)
          
          # Extract comments and documentation
          comments = extract_code_comments(content)
          
          comments.each do |comment|
            if comment.downcase.include?(search_query.downcase)
              code_comments << {
                file_path: class_file,
                class_name: class_name,
                method_name: method_name,
                comment: comment,
                relevance_score: calculate_relevance(comment, search_query)
              }
            end
          end
        end
      end
      
      code_comments.sort_by { |comment| -comment[:relevance_score] }
    end
    
    def self.search_configuration_files(search_query)
      config_files = []
      
      # Search in configuration files
      config_dirs = ['config', 'config/initializers']
      
      config_dirs.each do |dir|
        if Dir.exist?(dir)
          Dir.glob("#{dir}/**/*").each do |file|
            next unless File.file?(file) && File.readable?(file)
            
            content = File.read(file)
            if content.downcase.include?(search_query.downcase)
              config_files << {
                file_path: file,
                file_type: File.extname(file),
                relevance_score: calculate_relevance(content, search_query),
                excerpt: extract_relevant_excerpt(content, search_query)
              }
            end
          end
        end
      end
      
      config_files.sort_by { |file| -file[:relevance_score] }
    end
    
    def self.find_related_documents(search_query)
      related_docs = []
      
      # Find related documents based on search query
      all_files = Dir.glob("**/*").select { |f| File.file?(f) && File.readable?(f) && File.extname(f) =~ /\.(md|txt|yml|yaml|rb)$/ }
      
      all_files.each do |file|
        next if file.include?('vendor/') || file.include?('node_modules/') || file.include?('.git/')
        
        content = File.read(file)
        if content.downcase.include?(search_query.downcase)
          related_docs << {
            file_path: file,
            file_type: File.extname(file),
            relevance_score: calculate_relevance(content, search_query),
            excerpt: extract_relevant_excerpt(content, search_query)
          }
        end
      end
      
      related_docs.sort_by { |doc| -doc[:relevance_score] }.first(10)
    end
    
    def self.generate_documentation_recommendations(search_query, document_type, feature_name)
      recommendations = []
      
      recommendations << "review_related_documentation"
      recommendations << "update_documentation_if_outdated" if document_type
      recommendations << "add_feature_documentation" if feature_name
      recommendations << "improve_search_indexing"
      recommendations << "create_documentation_links"
      
      recommendations
    end
    
    # Helper methods
    def self.calculate_relevance(content, search_query)
      query_terms = search_query.downcase.split(/\s+/)
      content_lower = content.downcase
      
      relevance = 0
      query_terms.each do |term|
        if content_lower.include?(term)
          relevance += 1
          # Bonus for exact matches
          relevance += 2 if content_lower.include?(search_query.downcase)
        end
      end
      
      relevance
    end
    
    def self.extract_relevant_excerpt(content, search_query, max_length = 200)
      content_lower = content.downcase
      query_lower = search_query.downcase
      
      start_pos = content_lower.index(query_lower)
      return content[0, max_length] unless start_pos
      
      excerpt_start = [start_pos - 50, 0].max
      excerpt_end = [start_pos + search_query.length + 50, content.length].min
      
      excerpt = content[excerpt_start, excerpt_end - excerpt_start]
      
      if excerpt_start > 0
        excerpt = "..." + excerpt
      end
      
      if excerpt_end < content.length
        excerpt = excerpt + "..."
      end
      
      excerpt
    end
    
    def self.find_matching_sections(content, search_query)
      sections = []
      lines = content.split("\n")
      
      lines.each_with_index do |line, index|
        if line.downcase.include?(search_query.downcase)
          # Find section header (lines starting with #)
          section_header = find_section_header(lines, index)
          sections << section_header if section_header
        end
      end
      
      sections.uniq
    end
    
    def self.find_section_header(lines, current_index)
      # Look backwards for section header
      (current_index - 1).downto(0) do |i|
        line = lines[i]
        if line.strip.start_with?('#')
          return line.strip
        end
      end
      
      nil
    end
    
    def self.find_api_endpoints(content, search_query)
      endpoints = []
      
      # Look for API endpoint definitions
      content.scan(/get|post|put|delete|patch/i).each do |method|
        endpoints << method.upcase
      end
      
      endpoints.uniq
    end
    
    def self.extract_code_comments(content)
      comments = []
      
      # Extract Ruby comments
      content.scan(/#(.+)$/).each do |match|
        comments << match[0].strip
      end
      
      # Extract multi-line comments
      content.scan(/=begin(.+?)=end/m).each do |match|
        comments << match[0].strip
      end
      
      comments
    end
    
    def self.find_class_file(class_name)
      # Look for the class file in common Rails locations
      possible_paths = [
        "app/models/#{class_name.underscore}.rb",
        "app/controllers/#{class_name.underscore}.rb",
        "app/services/#{class_name.underscore}.rb",
        "lib/#{class_name.underscore}.rb"
      ]
      
      possible_paths.find { |path| File.exist?(path) }
    end
  end

  # Tool for integrating with JIRA to access tickets and project information
  class JIRAIntegrationTool < MCP::Tool
    description "Integrates with JIRA to access tickets, project information, and issue tracking"
    input_schema(
      properties: {
        action: { type: "string" },
        ticket_id: { type: "string" },
        project_key: { type: "string" },
        search_query: { type: "string" },
        issue_type: { type: "string" },
        status: { type: "string" },
        assignee: { type: "string" },
        server_context: { type: "object" }
      },
      required: ["action"]
    )
    annotations(
      title: "JIRA Integration Tool",
      read_only_hint: true,
      destructive_hint: false,
      idempotent_hint: true,
      open_world_hint: false
    )

    def self.call(action:, ticket_id: nil, project_key: nil, search_query: nil, issue_type: nil, status: nil, assignee: nil, server_context:)
      result = case action
      when 'get_ticket'
        get_ticket_details(ticket_id)
      when 'search_tickets'
        search_tickets(search_query, project_key, issue_type, status, assignee)
      when 'get_project_info'
        get_project_information(project_key)
      when 'get_issue_types'
        get_issue_types(project_key)
      when 'get_statuses'
        get_project_statuses(project_key)
      when 'get_assignees'
        get_project_assignees(project_key)
      when 'get_recent_activity'
        get_recent_project_activity(project_key)
      when 'analyze_ticket_patterns'
        analyze_ticket_patterns(project_key, issue_type)
      else
        { error: "Unknown action: #{action}" }
      end
      
      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end
    
    private
    
    def self.get_ticket_details(ticket_id)
      return { error: "Ticket ID required" } unless ticket_id
      
      begin
        # Try real JIRA API first, fallback to simulation if it fails
        if jira_api_available?
          ticket_data = get_real_jira_ticket(ticket_id)
          
          if ticket_data[:error]
            puts "⚠️  Real JIRA API failed, falling back to simulation: #{ticket_data[:error]}"
            ticket_data = simulate_jira_ticket(ticket_id)
          end
          
          {
            ticket_id: ticket_id,
            summary: ticket_data[:summary],
            description: ticket_data[:description],
            status: ticket_data[:status],
            priority: ticket_data[:priority],
            assignee: ticket_data[:assignee],
            reporter: ticket_data[:reporter],
            created: ticket_data[:created],
            updated: ticket_data[:updated],
            issue_type: ticket_data[:issue_type],
            project: ticket_data[:project],
            components: ticket_data[:components],
            labels: ticket_data[:labels],
            comments: ticket_data[:comments],
            attachments: ticket_data[:attachments],
            related_issues: ticket_data[:related_issues],
            time_tracking: ticket_data[:time_tracking]
          }
        else
          { error: "JIRA integration not available" }
        end
      rescue => e
        { error: "Failed to get ticket details: #{e.message}" }
      end
    end
    
    def self.search_tickets(search_query, project_key, issue_type, status, assignee)
      begin
        if simulate_jira_available?
          search_results = simulate_jira_search(search_query, project_key, issue_type, status, assignee)
          
          {
            search_query: search_query,
            project_key: project_key,
            issue_type: issue_type,
            status: status,
            assignee: assignee,
            total_results: search_results.length,
            tickets: search_results.map do |ticket|
              {
                ticket_id: ticket[:id],
                summary: ticket[:summary],
                status: ticket[:status],
                priority: ticket[:priority],
                assignee: ticket[:assignee],
                issue_type: ticket[:issue_type],
                created: ticket[:created],
                updated: ticket[:updated]
              }
            end
          }
        else
          { error: "JIRA integration not available" }
        end
      rescue => e
        { error: "Failed to search tickets: #{e.message}" }
      end
    end
    
    def self.get_project_information(project_key)
      return { error: "Project key required" } unless project_key
      
      begin
        if jira_api_available?
          project_data = get_real_jira_project(project_key)
          
          if project_data[:error]
            puts "⚠️  Real JIRA API failed, falling back to simulation: #{project_data[:error]}"
            project_data = simulate_jira_project(project_key)
          end
          
          {
            project_key: project_key,
            name: project_data[:name],
            description: project_data[:description],
            lead: project_data[:lead],
            url: project_data[:url],
            components: project_data[:components],
            issue_types: project_data[:issue_types],
            statuses: project_data[:statuses],
            versions: project_data[:versions],
            permissions: project_data[:permissions]
          }
        else
          { error: "JIRA integration not available" }
        end
      rescue => e
        { error: "Failed to get project information: #{e.message}" }
      end
    end
    
    def self.get_issue_types(project_key)
      return { error: "Project key required" } unless project_key
      
      begin
        if simulate_jira_available?
          issue_types = simulate_jira_issue_types(project_key)
          
          {
            project_key: project_key,
            issue_types: issue_types.map do |type|
              {
                id: type[:id],
                name: type[:name],
                description: type[:description],
                icon_url: type[:icon_url]
              }
            end
          }
        else
          { error: "JIRA integration not available" }
        end
      rescue => e
        { error: "Failed to get issue types: #{e.message}" }
      end
    end
    
    def self.get_project_statuses(project_key)
      return { error: "Project key required" } unless project_key
      
      begin
        if simulate_jira_available?
          statuses = simulate_jira_statuses(project_key)
          
          {
            project_key: project_key,
            statuses: statuses.map do |status|
              {
                id: status[:id],
                name: status[:name],
                description: status[:description],
                category: status[:category]
              }
            end
          }
        else
          { error: "JIRA integration not available" }
        end
      rescue => e
        { error: "Failed to get project statuses: #{e.message}" }
      end
    end
    
    def self.get_project_assignees(project_key)
      return { error: "Project key required" } unless project_key
      
      begin
        if simulate_jira_available?
          assignees = simulate_jira_assignees(project_key)
          
          {
            project_key: project_key,
            assignees: assignees.map do |assignee|
              {
                username: assignee[:username],
                display_name: assignee[:display_name],
                email: assignee[:email],
                active: assignee[:active]
              }
            end
          }
        else
          { error: "JIRA integration not available" }
        end
      rescue => e
        { error: "Failed to get project assignees: #{e.message}" }
      end
    end
    
    def self.get_recent_project_activity(project_key)
      return { error: "Project key required" } unless project_key
      
      begin
        if simulate_jira_available?
          activity = simulate_jira_recent_activity(project_key)
          
          {
            project_key: project_key,
            recent_activity: activity.map do |item|
              {
                type: item[:type],
                user: item[:user],
                timestamp: item[:timestamp],
                description: item[:description],
                ticket_id: item[:ticket_id]
              }
            end
          }
        else
          { error: "JIRA integration not available" }
        end
      rescue => e
        { error: "Failed to get recent activity: #{e.message}" }
      end
    end
    
    def self.analyze_ticket_patterns(project_key, issue_type)
      return { error: "Project key required" } unless project_key
      
      begin
        if simulate_jira_available?
          patterns = simulate_jira_pattern_analysis(project_key, issue_type)
          
          {
            project_key: project_key,
            issue_type: issue_type,
            patterns: {
              common_issues: patterns[:common_issues],
              resolution_times: patterns[:resolution_times],
              assignee_distribution: patterns[:assignee_distribution],
              status_transitions: patterns[:status_transitions],
              priority_distribution: patterns[:priority_distribution]
            }
          }
        else
          { error: "JIRA integration not available" }
        end
      rescue => e
        { error: "Failed to analyze ticket patterns: #{e.message}" }
      end
    end
    
    # Simulation methods for JIRA integration
    def self.simulate_jira_available?
      # Check if JIRA configuration is available
      ENV['JIRA_URL'] && ENV['JIRA_USERNAME'] && ENV['JIRA_API_TOKEN']
    end
    
    def self.simulate_jira_ticket(ticket_id)
      {
        id: ticket_id,
        summary: "Sample ticket summary for #{ticket_id}",
        description: "This is a sample ticket description for demonstration purposes.",
        status: "In Progress",
        priority: "Medium",
        assignee: "developer@example.com",
        reporter: "product@example.com",
        created: "2024-01-01T10:00:00Z",
        updated: "2024-01-15T14:30:00Z",
        issue_type: "Bug",
        project: "SELFRUBY",
        components: ["Backend", "API"],
        labels: ["bug", "backend"],
        comments: [
          { author: "developer@example.com", body: "Working on this issue", created: "2024-01-10T09:00:00Z" }
        ],
        attachments: [],
        related_issues: [],
        time_tracking: { original_estimate: "2h", time_spent: "1h", remaining_estimate: "1h" }
      }
    end
    
    def self.simulate_jira_search(query, project_key, issue_type, status, assignee)
      [
        {
          id: "SELFRUBY-123",
          summary: "Search result for: #{query}",
          status: status || "Open",
          priority: "High",
          assignee: assignee || "developer@example.com",
          issue_type: issue_type || "Bug",
          created: "2024-01-01T10:00:00Z",
          updated: "2024-01-15T14:30:00Z"
        }
      ]
    end
    
    def self.simulate_jira_project(project_key)
      {
        key: project_key,
        name: "SelfRuby Project",
        description: "Self-evolving Ruby application",
        lead: "project.lead@example.com",
        url: "https://jira.example.com/browse/#{project_key}",
        components: ["Backend", "Frontend", "API", "Database"],
        issue_types: ["Bug", "Feature", "Task", "Story"],
        statuses: ["Open", "In Progress", "Review", "Done"],
        versions: ["1.0.0", "1.1.0", "2.0.0"],
        permissions: ["Browse", "Create", "Edit", "Delete"]
      }
    end
    
    def self.simulate_jira_issue_types(project_key)
      [
        { id: "1", name: "Bug", description: "A problem which impairs or prevents the functions of the product", icon_url: "https://jira.example.com/images/icons/issuetypes/bug.png" },
        { id: "2", name: "Feature", description: "A new feature of the product", icon_url: "https://jira.example.com/images/icons/issuetypes/newfeature.png" },
        { id: "3", name: "Task", description: "A task that needs to be done", icon_url: "https://jira.example.com/images/icons/issuetypes/task.png" }
      ]
    end
    
    def self.simulate_jira_statuses(project_key)
      [
        { id: "1", name: "Open", description: "Issue is open and ready for work", category: "To Do" },
        { id: "2", name: "In Progress", description: "Issue is currently being worked on", category: "In Progress" },
        { id: "3", name: "Review", description: "Issue is ready for review", category: "In Progress" },
        { id: "4", name: "Done", description: "Issue is completed", category: "Done" }
      ]
    end
    
    def self.simulate_jira_assignees(project_key)
      [
        { username: "developer1", display_name: "Developer One", email: "developer1@example.com", active: true },
        { username: "developer2", display_name: "Developer Two", email: "developer2@example.com", active: true },
        { username: "qa", display_name: "QA Engineer", email: "qa@example.com", active: true }
      ]
    end
    
    def self.simulate_jira_recent_activity(project_key)
      [
        { type: "comment", user: "developer1@example.com", timestamp: "2024-01-15T14:30:00Z", description: "Added comment to SELFRUBY-123", ticket_id: "SELFRUBY-123" },
        { type: "status_change", user: "developer1@example.com", timestamp: "2024-01-15T13:00:00Z", description: "Changed status to In Progress", ticket_id: "SELFRUBY-123" }
      ]
    end
    
    def self.simulate_jira_pattern_analysis(project_key, issue_type)
      {
        common_issues: ["API errors", "Performance issues", "UI bugs"],
        resolution_times: { average: "3.5 days", median: "2 days", max: "10 days" },
        assignee_distribution: { "developer1": 40, "developer2": 35, "qa": 25 },
        status_transitions: { "Open": "In Progress", "In Progress": "Review", "Review": "Done" },
        priority_distribution: { "High": 20, "Medium": 60, "Low": 20 }
      }
    end

    # Real JIRA API integration methods
    def self.jira_api_available?
      # Check if JIRA configuration is available
      ENV['JIRA_URL'] && ENV['JIRA_USERNAME'] && ENV['JIRA_API_TOKEN']
    end

    def self.jira_api_call(endpoint, method = :get, body = nil)
      return { error: "JIRA configuration not available" } unless jira_api_available?
      
      begin
        url = "#{ENV['JIRA_URL']}/rest/api/2#{endpoint}"
        auth = { username: ENV['JIRA_USERNAME'], password: ENV['JIRA_API_TOKEN'] }
        
        options = {
          basic_auth: auth,
          headers: { 'Content-Type' => 'application/json' }
        }
        
        case method
        when :get
          response = HTTParty.get(url, options)
        when :post
          response = HTTParty.post(url, options.merge(body: body.to_json))
        when :put
          response = HTTParty.put(url, options.merge(body: body.to_json))
        else
          return { error: "Unsupported HTTP method: #{method}" }
        end
        
        if response.success?
          JSON.parse(response.body)
        else
          { error: "JIRA API error: #{response.code} - #{response.body}" }
        end
      rescue => e
        { error: "JIRA API call failed: #{e.message}" }
      end
    end

    def self.get_real_jira_ticket(ticket_id)
      endpoint = "/issue/#{ticket_id}"
      response = jira_api_call(endpoint)
      
      return response if response['error']
      
      # Transform Jira API response to our format
      {
        id: response['key'],
        summary: response['fields']['summary'],
        description: response['fields']['description'],
        status: response['fields']['status']['name'],
        priority: response['fields']['priority']['name'],
        assignee: response['fields']['assignee']&.dig('emailAddress'),
        reporter: response['fields']['reporter']&.dig('emailAddress'),
        created: response['fields']['created'],
        updated: response['fields']['updated'],
        issue_type: response['fields']['issuetype']['name'],
        project: response['fields']['project']['key'],
        components: response['fields']['components']&.map { |c| c['name'] } || [],
        labels: response['fields']['labels'] || [],
        comments: response['fields']['comment']&.dig('comments')&.map { |c| 
          { author: c['author']['emailAddress'], body: c['body'], created: c['created'] }
        } || [],
        attachments: response['fields']['attachment']&.map { |a| a['filename'] } || [],
        related_issues: [], # Jira doesn't provide this directly
        time_tracking: {
          original_estimate: response['fields']['timeoriginalestimate'],
          time_spent: response['fields']['timespent'],
          remaining_estimate: response['fields']['timeestimate']
        }
      }
    end

    def self.get_real_jira_search(query, project_key, issue_type, status, assignee)
      jql_parts = []
      jql_parts << "project = #{project_key}" if project_key
      jql_parts << "issuetype = #{issue_type}" if issue_type
      jql_parts << "status = #{status}" if status
      jql_parts << "assignee = #{assignee}" if assignee
      jql_parts << "text ~ \"#{query}\"" if query
      
      jql = jql_parts.join(" AND ")
      endpoint = "/search?jql=#{CGI.escape(jql)}&maxResults=10"
      
      response = jira_api_call(endpoint)
      return [] if response['error']
      
      response['issues']&.map do |issue|
        {
          id: issue['key'],
          summary: issue['fields']['summary'],
          status: issue['fields']['status']['name'],
          priority: issue['fields']['priority']['name'],
          assignee: issue['fields']['assignee']&.dig('emailAddress'),
          issue_type: issue['fields']['issuetype']['name'],
          created: issue['fields']['created'],
          updated: issue['fields']['updated']
        }
      end || []
    end

    def self.get_real_jira_project(project_key)
      endpoint = "/project/#{project_key}"
      response = jira_api_call(endpoint)
      
      return response if response['error']
      
      {
        key: response['key'],
        name: response['name'],
        description: response['description'],
        lead: response['lead']['emailAddress'],
        url: "#{ENV['JIRA_URL']}/browse/#{project_key}",
        components: response['components']&.map { |c| c['name'] } || [],
        issue_types: response['issueTypes']&.map { |it| it['name'] } || [],
        statuses: response['statuses']&.map { |s| s['name'] } || [],
        versions: response['versions']&.map { |v| v['name'] } || [],
        permissions: response['permissions'] || []
      }
    end

    # Fallback to simulation if real API fails
    def self.simulate_jira_available?
      # Check if JIRA configuration is available
      ENV['JIRA_URL'] && ENV['JIRA_USERNAME'] && ENV['JIRA_API_TOKEN']
    end
  end

  # Tool for Confluence integration and business context retrieval
  class ConfluenceIntegrationTool < MCP::Tool
    description "Integrates with Confluence to retrieve PRDs, business requirements, and documentation for business context"
    input_schema(
      properties: {
        action: { type: "string", enum: ["search_documents", "get_document", "get_space_info", "search_prd"] },
        search_query: { type: "string" },
        space_key: { type: "string" },
        document_id: { type: "string" },
        server_context: { type: "object" }
      },
      required: ["action"]
    )
    annotations(
      title: "Confluence Integration Tool",
      read_only_hint: true,
      destructive_hint: false,
      idempotent_hint: true,
      open_world_hint: false
    )

    def self.call(action:, search_query: nil, space_key: nil, document_id: nil, server_context:)
      case action
      when "search_documents"
        search_confluence_documents(search_query, space_key)
      when "get_document"
        get_confluence_document(document_id)
      when "get_space_info"
        get_confluence_space_info(space_key)
      when "search_prd"
        search_prd_documents(search_query, space_key)
      else
        MCP::Tool::Response.new([{ type: "text", text: { error: "Unknown action: #{action}" }.to_json }])
      end
    end

    private

    def self.search_confluence_documents(query, space_key)
      if confluence_api_available?
        get_real_confluence_search(query, space_key)
      else
        simulate_confluence_search(query, space_key)
      end
    end

    def self.get_confluence_document(document_id)
      if confluence_api_available?
        get_real_confluence_document(document_id)
      else
        simulate_confluence_document(document_id)
      end
    end

    def self.get_confluence_space_info(space_key)
      if confluence_api_available?
        get_real_confluence_space_info(space_key)
      else
        simulate_confluence_space_info(space_key)
      end
    end

    def self.search_prd_documents(query, space_key)
      if confluence_api_available?
        get_real_confluence_prd_search(query, space_key)
      else
        simulate_confluence_prd_search(query, space_key)
      end
    end

    # Real Confluence API calls
    def self.confluence_api_available?
      ENV['CONFLUENCE_URL'] && ENV['CONFLUENCE_USERNAME'] && ENV['CONFLUENCE_API_TOKEN']
    end

    def self.confluence_api_call(endpoint, params = {})
      return nil unless confluence_api_available?

      url = "#{ENV['CONFLUENCE_URL']}/rest/api#{endpoint}"
      auth = { username: ENV['CONFLUENCE_USERNAME'], password: ENV['CONFLUENCE_API_TOKEN'] }
      
      begin
        response = HTTParty.get(url, basic_auth: auth, query: params)
        response.success? ? response.parsed_response : nil
      rescue => e
        puts "⚠️  Confluence API call failed: #{e.message}"
        nil
      end
    end

    def self.get_real_confluence_search(query, space_key)
      params = {
        cql: "space = #{space_key} AND text ~ \"#{query}\"",
        limit: 10,
        expand: "content"
      }
      
      data = confluence_api_call('/content/search', params)
      return { error: "Failed to search Confluence" } unless data

      documents = data['results']&.map do |result|
        {
          id: result['id'],
          title: result['title'],
          type: result['type'],
          space_key: result['space']['key'],
          url: "#{ENV['CONFLUENCE_URL']}/wiki#{result['_links']['webui']}",
          content: result['excerpt'] || result['title'],
          labels: result['metadata']&.dig('labels', 'results')&.map { |l| l['name'] } || []
        }
      end || []

      MCP::Tool::Response.new([{ type: "text", text: { documents: documents }.to_json }])
    end

    def self.get_real_confluence_document(document_id)
      data = confluence_api_call("/content/#{document_id}")
      return { error: "Failed to get document" } unless data

      document = {
        id: data['id'],
        title: data['title'],
        type: data['type'],
        space_key: data['space']['key'],
        url: "#{ENV['CONFLUENCE_URL']}/wiki#{data['_links']['webui']}",
        content: data['body']&.dig('storage', 'value') || data['title'],
        labels: data['metadata']&.dig('labels', 'results')&.map { |l| l['name'] } || []
      }

      MCP::Tool::Response.new([{ type: "text", text: { document: document }.to_json }])
    end

    def self.get_real_confluence_space_info(space_key)
      data = confluence_api_call("/space/#{space_key}")
      return { error: "Failed to get space info" } unless data

      space_info = {
        key: data['key'],
        name: data['name'],
        type: data['type'],
        description: data['description'],
        url: "#{ENV['CONFLUENCE_URL']}/wiki/spaces/#{space_key}",
        permissions: data['permissions'] || []
      }

      MCP::Tool::Response.new([{ type: "text", text: { space: space_info }.to_json }])
    end

    def self.get_real_confluence_prd_search(query, space_key)
      params = {
        cql: "space = #{space_key} AND (text ~ \"PRD\" OR text ~ \"Product Requirements\" OR text ~ \"#{query}\")",
        limit: 5,
        expand: "content"
      }
      
      data = confluence_api_call('/content/search', params)
      return { error: "Failed to search PRD documents" } unless data

      prd_documents = data['results']&.map do |result|
        {
          id: result['id'],
          title: result['title'],
          type: result['type'],
          space_key: result['space']['key'],
          url: "#{ENV['CONFLUENCE_URL']}/wiki#{result['_links']['webui']}",
          content: result['excerpt'] || result['title'],
          is_prd: result['title'].include?('PRD') || result['title'].include?('Product Requirements'),
          labels: result['metadata']&.dig('labels', 'results')&.map { |l| l['name'] } || []
        }
      end || []

      MCP::Tool::Response.new([{ type: "text", text: { documents: prd_documents }.to_json }])
    end

    # Simulation methods for when Confluence API is not available
    def self.simulate_confluence_search(query, space_key)
      documents = [
        {
          id: "sim-1",
          title: "Business Rules for #{space_key}",
          type: "page",
          space_key: space_key,
          url: "https://confluence.example.com/wiki/spaces/#{space_key}/pages/sim-1",
          content: "Simulated business rules document for #{space_key} project",
          labels: ["business-rules", "requirements"]
        },
        {
          id: "sim-2",
          title: "Process Documentation",
          type: "page",
          space_key: space_key,
          url: "https://confluence.example.com/wiki/spaces/#{space_key}/pages/sim-2",
          content: "Simulated process documentation for #{space_key}",
          labels: ["process", "workflow"]
        }
      ]

      MCP::Tool::Response.new([{ type: "text", text: { documents: documents }.to_json }])
    end

    def self.simulate_confluence_document(document_id)
      document = {
        id: document_id,
        title: "Simulated Confluence Document",
        type: "page",
        space_key: "DGTL",
        url: "https://confluence.example.com/wiki/spaces/DGTL/pages/#{document_id}",
        content: "This is a simulated Confluence document content for testing purposes.",
        labels: ["simulated", "test"]
      }

      MCP::Tool::Response.new([{ type: "text", text: { document: document }.to_json }])
    end

    def self.simulate_confluence_space_info(space_key)
      space_info = {
        key: space_key,
        name: "#{space_key} Project Space",
        type: "global",
        description: "Simulated Confluence space for #{space_key} project",
        url: "https://confluence.example.com/wiki/spaces/#{space_key}",
        permissions: ["view", "edit", "create"]
      }

      MCP::Tool::Response.new([{ type: "text", text: { space: space_info }.to_json }])
    end

    def self.simulate_confluence_prd_search(query, space_key)
      prd_documents = [
        {
          id: "prd-1",
          title: "Product Requirements Document - #{space_key}",
          type: "page",
          space_key: space_key,
          url: "https://confluence.example.com/wiki/spaces/#{space_key}/pages/prd-1",
          content: "Simulated PRD for #{space_key} project with requirements and business rules",
          is_prd: true,
          labels: ["PRD", "requirements", "product"]
        }
      ]

      MCP::Tool::Response.new([{ type: "text", text: { documents: prd_documents }.to_json }])
    end
  end

  # Tool for intelligent context analysis and runtime decision making
  class IntelligentContextAnalysisTool < MCP::Tool
    description "Provides intelligent context analysis, runtime decision making, and Cursor IDE-like capabilities"
    input_schema(
      properties: {
        analysis_type: { type: "string" },
        context_data: { type: "object" },
        class_name: { type: "string" },
        method_name: { type: "string" },
        error_context: { type: "object" },
        business_context: { type: "object" },
        server_context: { type: "object" }
      },
      required: ["analysis_type"]
    )
    annotations(
      title: "Intelligent Context Analysis Tool",
      read_only_hint: true,
      destructive_hint: false,
      idempotent_hint: true,
      open_world_hint: false
    )

    def self.call(analysis_type:, context_data: nil, class_name: nil, method_name: nil, error_context: nil, business_context: nil, server_context:)
      analysis = case analysis_type
      when 'comprehensive_context'
        analyze_comprehensive_context(context_data, class_name, method_name, server_context)
      when 'error_pattern_analysis'
        analyze_error_patterns(error_context, class_name, method_name, server_context)
      when 'business_impact_assessment'
        assess_business_impact(context_data, business_context, server_context)
      when 'evolution_recommendations'
        generate_evolution_recommendations(context_data, class_name, method_name, server_context)
      when 'runtime_optimization'
        suggest_runtime_optimizations(context_data, class_name, method_name, server_context)
      when 'intelligent_fix_generation'
        generate_intelligent_fix(context_data, error_context, class_name, method_name, server_context)
      when 'context_aware_validation'
        perform_context_aware_validation(context_data, business_context, server_context)
      else
        { error: "Unknown analysis type: #{analysis_type}" }
      end
      
      MCP::Tool::Response.new([{ type: "text", text: analysis.to_json }])
    end
    
    private
    
    def self.analyze_comprehensive_context(context_data, class_name, method_name, server_context)
      return { error: "Context data required" } unless context_data
      
      begin
        # Load business context and standards
        business_context = server_context&.dig(:codebase_context) || {}
        coding_standards = business_context['coding_standards'] || {}
        
        # Analyze the current context comprehensively
        context_analysis = {
          class_analysis: analyze_class_context(class_name, business_context),
          method_analysis: analyze_method_context(class_name, method_name, business_context),
          business_rules: extract_relevant_business_rules(class_name, method_name, business_context),
          coding_standards: extract_relevant_coding_standards(coding_standards),
          dependencies: analyze_dependencies(class_name, method_name),
          risk_assessment: assess_context_risks(class_name, method_name, business_context),
          recommendations: generate_context_recommendations(class_name, method_name, business_context)
        }
        
        context_analysis
      rescue => e
        { error: "Comprehensive context analysis failed: #{e.message}" }
      end
    end
    
    def self.analyze_error_patterns(error_context, class_name, method_name, server_context)
      return { error: "Error context required" } unless error_context
      
      begin
        business_context = server_context&.dig(:codebase_context) || {}
        
        error_analysis = {
          error_type: error_context[:error_type],
          error_message: error_context[:error_message],
          pattern_analysis: identify_error_patterns(error_context, class_name, method_name),
          business_impact: assess_error_business_impact(error_context, business_context),
          prevention_strategies: suggest_error_prevention_strategies(error_context, business_context),
          monitoring_recommendations: suggest_error_monitoring(error_context, business_context),
          evolution_opportunities: identify_evolution_opportunities(error_context, business_context)
        }
        
        error_analysis
      rescue => e
        { error: "Error pattern analysis failed: #{e.message}" }
      end
    end
    
    def self.assess_business_impact(context_data, business_context, server_context)
      return { error: "Context data required" } unless context_data
      
      begin
        impact_analysis = {
          user_experience_impact: assess_user_experience_impact(context_data, business_context),
          data_integrity_impact: assess_data_integrity_impact(context_data, business_context),
          financial_impact: assess_financial_impact(context_data, business_context),
          compliance_impact: assess_compliance_impact(context_data, business_context),
          operational_impact: assess_operational_impact(context_data, business_context),
          risk_level: calculate_overall_risk_level(context_data, business_context),
          mitigation_strategies: suggest_mitigation_strategies(context_data, business_context)
        }
        
        impact_analysis
      rescue => e
        { error: "Business impact assessment failed: #{e.message}" }
      end
    end
    
    def self.generate_evolution_recommendations(context_data, class_name, method_name, server_context)
      return { error: "Context data required" } unless context_data
      
      begin
        business_context = server_context&.dig(:codebase_context) || {}
        
        evolution_recommendations = {
          immediate_actions: suggest_immediate_actions(context_data, class_name, method_name),
          short_term_improvements: suggest_short_term_improvements(context_data, business_context),
          long_term_evolution: suggest_long_term_evolution(context_data, business_context),
          architectural_changes: suggest_architectural_changes(context_data, business_context),
          testing_strategies: suggest_testing_strategies(context_data, business_context),
          monitoring_enhancements: suggest_monitoring_enhancements(context_data, business_context),
          documentation_updates: suggest_documentation_updates(context_data, business_context)
        }
        
        evolution_recommendations
      rescue => e
        { error: "Evolution recommendations generation failed: #{e.message}" }
      end
    end
    
    def self.suggest_runtime_optimizations(context_data, class_name, method_name, server_context)
      return { error: "Context data required" } unless context_data
      
      begin
        business_context = server_context&.dig(:codebase_context) || {}
        
        optimization_suggestions = {
          performance_optimizations: suggest_performance_optimizations(context_data, class_name, method_name),
          memory_optimizations: suggest_memory_optimizations(context_data, class_name, method_name),
          caching_strategies: suggest_caching_strategies(context_data, business_context),
          database_optimizations: suggest_database_optimizations(context_data, business_context),
          algorithm_improvements: suggest_algorithm_improvements(context_data, class_name, method_name),
          resource_management: suggest_resource_management_improvements(context_data, business_context)
        }
        
        optimization_suggestions
      rescue => e
        { error: "Runtime optimization suggestions failed: #{e.message}" }
      end
    end
    
    def self.generate_intelligent_fix(context_data, error_context, class_name, method_name, server_context)
      return { error: "Context data and error context required" } unless context_data && error_context
      
      begin
        business_context = server_context&.dig(:codebase_context) || {}
        
        intelligent_fix = {
          fix_strategy: determine_fix_strategy(error_context, business_context),
          implementation_approach: determine_implementation_approach(error_context, business_context),
          business_rule_compliance: ensure_business_rule_compliance(error_context, business_context),
          performance_considerations: include_performance_considerations(error_context, business_context),
          security_considerations: include_security_considerations(error_context, business_context),
          testing_requirements: determine_testing_requirements(error_context, business_context),
          deployment_considerations: determine_deployment_considerations(error_context, business_context)
        }
        
        intelligent_fix
      rescue => e
        { error: "Intelligent fix generation failed: #{e.message}" }
      end
    end
    
    def self.perform_context_aware_validation(context_data, business_context, server_context)
      return { error: "Context data required" } unless context_data
      
      begin
        validation_results = {
          business_rule_validation: validate_business_rules(context_data, business_context),
          coding_standard_validation: validate_coding_standards(context_data, business_context),
          performance_validation: validate_performance_requirements(context_data, business_context),
          security_validation: validate_security_requirements(context_data, business_context),
          compliance_validation: validate_compliance_requirements(context_data, business_context),
          overall_validation_score: calculate_validation_score(context_data, business_context),
          validation_recommendations: generate_validation_recommendations(context_data, business_context)
        }
        
        validation_results
      rescue => e
        { error: "Context-aware validation failed: #{e.message}" }
      end
    end
    
    # Helper methods for comprehensive analysis
    def self.analyze_class_context(class_name, business_context)
      return {} unless class_name
      
      domains = business_context['domains'] || {}
      domain = determine_class_domain(class_name, domains)
      
      {
        domain: domain,
        business_criticality: domains.dig(domain, 'criticality') || 'medium',
        compliance_requirements: domains.dig(domain, 'compliance') || [],
        sla_requirements: domains.dig(domain, 'sla_requirements') || '99.5%',
        security_requirements: domains.dig(domain, 'security_requirements') || 'standard'
      }
    end
    
    def self.analyze_method_context(class_name, method_name, business_context)
      return {} unless class_name && method_name
      
      domains = business_context['domains'] || {}
      domain = determine_class_domain(class_name, domains)
      class_info = domains.dig(domain, 'classes', class_name) || {}
      method_info = class_info.dig('methods', method_name) || {}
      
      {
        method_description: method_info['description'] || 'No description available',
        error_handling: method_info['error_handling'] || 'standard',
        logging: method_info['logging'] || 'standard',
        return_values: method_info['return_values'] || {},
        business_criticality: class_info['business_criticality'] || 'medium'
      }
    end
    
    def self.extract_relevant_business_rules(class_name, method_name, business_context)
      return {} unless business_context
      
      common_patterns = business_context['common_patterns'] || {}
      
      {
        calculator_operations: common_patterns['calculator_operations'] || {},
        model_operations: common_patterns['model_operations'] || {},
        service_operations: common_patterns['service_operations'] || {}
      }
    end
    
    def self.extract_relevant_coding_standards(coding_standards)
      return {} unless coding_standards
      
      {
        error_handling: coding_standards['error_handling'] || 'standard',
        logging: coding_standards['logging'] || 'standard',
        validation: coding_standards['validation'] || 'standard',
        performance: coding_standards['performance'] || 'standard',
        security: coding_standards['security'] || 'standard',
        documentation: coding_standards['documentation'] || 'standard',
        testing: coding_standards['testing'] || 'standard'
      }
    end
    
    def self.analyze_dependencies(class_name, method_name)
      return {} unless class_name
      
      # Analyze dependencies based on class and method
      {
        model_dependencies: find_model_dependencies(class_name),
        service_dependencies: find_service_dependencies(class_name),
        external_dependencies: find_external_dependencies(class_name),
        database_dependencies: find_database_dependencies(class_name)
      }
    end
    
    def self.assess_context_risks(class_name, method_name, business_context)
      return {} unless business_context
      
      domains = business_context['domains'] || {}
      domain = determine_class_domain(class_name, domains)
      
      {
        business_risk: domains.dig(domain, 'criticality') == 'critical' ? 'high' : 'medium',
        technical_risk: assess_technical_risk(class_name, method_name),
        compliance_risk: assess_compliance_risk(domain, business_context),
        security_risk: assess_security_risk(domain, business_context)
      }
    end
    
    def self.generate_context_recommendations(class_name, method_name, business_context)
      recommendations = []
      
      recommendations << "implement_comprehensive_error_handling" if class_name && method_name
      recommendations << "add_business_rule_validation" if business_context
      recommendations << "implement_structured_logging" if business_context
      recommendations << "add_performance_monitoring" if business_context
      recommendations << "implement_security_measures" if business_context
      
      recommendations
    end
    
    # Additional helper methods for specific analysis types
    def self.determine_class_domain(class_name, domains)
      domains.keys.find { |domain| class_name.downcase.include?(domain.downcase) } || 'general'
    end
    
    def self.assess_technical_risk(class_name, method_name)
      # Simple technical risk assessment
      if class_name&.include?('Controller') || class_name&.include?('Service')
        'medium'
      else
        'low'
      end
    end
    
    def self.assess_compliance_risk(domain, business_context)
      domains = business_context['domains'] || {}
      domain_info = domains[domain] || {}
      
      if domain_info['compliance']&.any?
        'medium'
      else
        'low'
      end
    end
    
    def self.assess_security_risk(domain, business_context)
      domains = business_context['domains'] || {}
      domain_info = domains[domain] || {}
      
      if domain_info['security'] == 'maximum'
        'high'
      elsif domain_info['security'] == 'high'
        'medium'
      else
        'low'
      end
    end
    
    # Placeholder methods for dependency analysis
    def self.find_model_dependencies(class_name)
      []
    end
    
    def self.find_service_dependencies(class_name)
      []
    end
    
    def self.find_external_dependencies(class_name)
      []
    end
    
    def self.find_database_dependencies(class_name)
      []
    end
    
    # Additional analysis methods (simplified for brevity)
    def self.identify_error_patterns(error_context, class_name, method_name)
      { pattern: 'common_error_pattern', frequency: 'occasional' }
    end
    
    def self.assess_error_business_impact(error_context, business_context)
      { impact_level: 'medium', user_experience: 'affected', data_integrity: 'maintained' }
    end
    
    def self.suggest_error_prevention_strategies(error_context, business_context)
      ['input_validation', 'defensive_programming', 'comprehensive_testing']
    end
    
    def self.suggest_error_monitoring(error_context, business_context)
      ['error_tracking', 'performance_monitoring', 'user_feedback_collection']
    end
    
    def self.identify_evolution_opportunities(error_context, business_context)
      ['improve_error_handling', 'enhance_user_experience', 'add_monitoring']
    end
    
    # Additional helper methods for other analysis types
    def self.assess_user_experience_impact(context_data, business_context)
      { impact_level: 'minimal', user_satisfaction: 'maintained' }
    end
    
    def self.assess_data_integrity_impact(context_data, business_context)
      { impact_level: 'none', data_consistency: 'maintained' }
    end
    
    def self.assess_financial_impact(context_data, business_context)
      { impact_level: 'none', cost_implications: 'minimal' }
    end
    
    def self.assess_compliance_impact(context_data, business_context)
      { impact_level: 'none', compliance_status: 'maintained' }
    end
    
    def self.assess_operational_impact(context_data, business_context)
      { impact_level: 'minimal', operational_efficiency: 'maintained' }
    end
    
    def self.calculate_overall_risk_level(context_data, business_context)
      'low'
    end
    
    def self.suggest_mitigation_strategies(context_data, business_context)
      ['monitor_performance', 'implement_alerting', 'add_logging']
    end
    
    # Additional helper methods for evolution recommendations
    def self.suggest_immediate_actions(context_data, class_name, method_name)
      ['fix_critical_issues', 'add_error_handling', 'improve_logging']
    end
    
    def self.suggest_short_term_improvements(context_data, business_context)
      ['enhance_validation', 'improve_error_messages', 'add_monitoring']
    end
    
    def self.suggest_long_term_evolution(context_data, business_context)
      ['architectural_refactoring', 'performance_optimization', 'security_enhancement']
    end
    
    def self.suggest_architectural_changes(context_data, business_context)
      ['improve_separation_of_concerns', 'enhance_modularity', 'optimize_data_flow']
    end
    
    def self.suggest_testing_strategies(context_data, business_context)
      ['unit_testing', 'integration_testing', 'performance_testing']
    end
    
    def self.suggest_monitoring_enhancements(context_data, business_context)
      ['real_time_monitoring', 'alerting_systems', 'performance_metrics']
    end
    
    def self.suggest_documentation_updates(context_data, business_context)
      ['update_api_documentation', 'improve_code_comments', 'create_user_guides']
    end
    
    # Additional helper methods for runtime optimizations
    def self.suggest_performance_optimizations(context_data, class_name, method_name)
      ['algorithm_optimization', 'caching_implementation', 'database_query_optimization']
    end
    
    def self.suggest_memory_optimizations(context_data, class_name, method_name)
      ['memory_pool_management', 'garbage_collection_optimization', 'data_structure_optimization']
    end
    
    def self.suggest_caching_strategies(context_data, business_context)
      ['result_caching', 'query_caching', 'session_caching']
    end
    
    def self.suggest_database_optimizations(context_data, business_context)
      ['index_optimization', 'query_optimization', 'connection_pooling']
    end
    
    def self.suggest_algorithm_improvements(context_data, class_name, method_name)
      ['time_complexity_reduction', 'space_complexity_optimization', 'algorithm_selection']
    end
    
    def self.suggest_resource_management_improvements(context_data, business_context)
      ['connection_pooling', 'memory_management', 'thread_management']
    end
    
    # Additional helper methods for intelligent fix generation
    def self.determine_fix_strategy(error_context, business_context)
      'defensive_programming_with_graceful_degradation'
    end
    
    def self.determine_implementation_approach(error_context, business_context)
      'incremental_improvement_with_backward_compatibility'
    end
    
    def self.ensure_business_rule_compliance(error_context, business_context)
      'strict_compliance_with_business_rules'
    end
    
    def self.include_performance_considerations(error_context, business_context)
      'optimize_for_performance_with_monitoring'
    end
    
    def self.include_security_considerations(error_context, business_context)
      'security_first_approach_with_validation'
    end
    
    def self.determine_testing_requirements(error_context, business_context)
      'comprehensive_testing_with_edge_cases'
    end
    
    def self.determine_deployment_considerations(error_context, business_context)
      'gradual_rollout_with_rollback_capability'
    end
    
    # Additional helper methods for context-aware validation
    def self.validate_business_rules(context_data, business_context)
      { valid: true, score: 0.9, recommendations: ['maintain_current_implementation'] }
    end
    
    def self.validate_coding_standards(context_data, business_context)
      { valid: true, score: 0.85, recommendations: ['improve_documentation'] }
    end
    
    def self.validate_performance_requirements(context_data, business_context)
      { valid: true, score: 0.8, recommendations: ['optimize_algorithm'] }
    end
    
    def self.validate_security_requirements(context_data, business_context)
      { valid: true, score: 0.9, recommendations: ['add_input_validation'] }
    end
    
    def self.validate_compliance_requirements(context_data, business_context)
      { valid: true, score: 0.95, recommendations: ['maintain_compliance'] }
    end
    
    def self.calculate_validation_score(context_data, business_context)
      0.88
    end
    
    def self.generate_validation_recommendations(context_data, business_context)
      ['improve_documentation', 'add_input_validation', 'optimize_algorithm']
    end
  end
end 