module CodeHealer
  # Presentation-focused logger for clean operator output
  class PresentationLogger
    class << self
      def verbose?
        env_flag = ENV.fetch('CODE_HEALER_VERBOSE', 'false')
        env_flag.to_s.downcase == 'true'
      end

      def section(title)
        divider
        puts "\n🎤  #{title}\n"
      end

      def step(message)
        puts "➡️  #{message}"
      end

      def info(message)
        puts "ℹ️  #{message}"
      end

      def success(message)
        puts "✅ #{message}"
      end

      def warn(message)
        puts "⚠️  #{message}"
      end

      def error(message)
        puts "❌ #{message}"
      end

      def detail(message)
        return unless verbose?
        puts "   · #{message}"
      end

      def kv(label, value)
        # Truncate long values for presentation
        display_value = case value
        when Array
          if value.length > 3
            "#{value.first(2).join(', ')}... (#{value.length} total)"
          else
            value.join(', ')
          end
        when String
          value.length > 100 ? "#{value[0..97]}..." : value
        else
          value.to_s
        end
        puts "   • #{label}: #{display_value}"
      end

      def backtrace(backtrace_array)
        return unless backtrace_array&.any?
        
        # Show only the first 3 relevant lines for presentation
        relevant_lines = backtrace_array.first(3).map do |line|
          # Extract just the file and line number for cleaner display
          if (m = line.match(/^(.+\.rb):(\d+):in/))
            file = File.basename(m[1])
            line_num = m[2]
            method = line.match(/in `(.+)'/)&.[](1) || 'unknown'
            "#{file}:#{line_num} in #{method}"
          else
            line
          end
        end
        
        puts "   • Backtrace: #{relevant_lines.join(' → ')}"
        detail("Full backtrace available with CODE_HEALER_VERBOSE=true") if backtrace_array.length > 3
      end

      def time(label, ms)
        puts "⏱️  #{label}: #{ms} ms"
      end

      def divider
        puts "\n────────────────────────────────────────────────────────\n"
      end

      def outcome(success:, branch: nil, pr_url: nil, reason: nil, timing: nil)
        if success
          success_msg = "🎉 Healing complete"
          success_msg << " (#{timing})" if timing
          success(success_msg)
          puts "   • Branch: #{branch}" if branch
          puts "   • PR: #{pr_url}" if pr_url
        else
          error_msg = "💥 Healing failed"
          error_msg << " (#{reason})" if reason
          error(error_msg)
        end
      end

      def claude_action(action)
        puts "🤖 #{action}"
      end

      def workspace_action(action)
        puts "🏗️  #{action}"
      end

      def git_action(action)
        puts "📝 #{action}"
      end
    end
  end
end


