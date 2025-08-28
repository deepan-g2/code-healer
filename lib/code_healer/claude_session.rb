require 'open3'

module CodeHealer
  # Manages a persistent Claude Code Terminal session and one-time preload
  class ClaudeSession
    class << self
      def start!
        return if @started
        return unless CodeHealer::ConfigManager.claude_code_enabled?

        @started = true
        preload_workspace
        preload_context
      rescue => e
        @started = false
        puts "⚠️ Failed to start Claude session preload: #{e.message}"
      end

      def with_session
        start!
        yield self
      end

      private

      def preload_workspace
        base = CodeHealer::ConfigManager.code_heal_directory_path
        path = CodeHealer::ConfigManager.sticky_workspace? ? File.join(base, 'session_workspace') : base
        @workspace_path = path

        FileUtils.mkdir_p(base)
        unless Dir.exist?(@workspace_path)
          # First run: create empty workspace folder; HealingWorkspaceManager will clone on demand
          FileUtils.mkdir_p(@workspace_path)
        end
      end

      def preload_context
        # Build a compact code map for the entire repo, excluding ignored paths
        repo_root = Rails.root.to_s
        ignore = CodeHealer::ConfigManager.claude_ignore_paths

        files = Dir.chdir(repo_root) do
          Dir.glob("**/*", File::FNM_DOTMATCH)
            .select { |f| File.file?(f) }
            .reject do |f|
              # Skip current/parent, VCS metadata, and ignored dirs/files
              f == '.' || f == '..' ||
                ignore.any? { |ig| f == ig || f.start_with?("#{ig}/") || f.include?("/#{ig}/") }
            end
        end

        map = files.map do |f|
          { file: f, size: File.size?(File.join(repo_root, f)) || 0 }
        end

        cache_dir = Rails.root.join('tmp')
        FileUtils.mkdir_p(cache_dir)
        File.write(cache_dir.join('code_healer_context.json'), JSON.pretty_generate(map))
        puts "🧠 Claude preload: indexed #{map.size} files (excluding ignores)"
      end
    end
  end
end


