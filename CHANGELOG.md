# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.24] - 2025-08-31

### Added
- **Aggressive File Filtering**: Implemented comprehensive filtering to prevent `tmp/`, `log/`, and other temporary files from being committed
- **Pre-Commit Validation**: Added workspace validation before commit to ensure no temporary files slip through
- **Mandatory MCP Usage**: Enhanced business context prompts to force Claude to use Atlassian MCP tools for Confluence/Jira integration
- **Missing Method Fix**: Added `extract_file_path_from_error` method to resolve undefined method errors

### Changed
- **File Filtering**: Enhanced `should_skip_file?` method with aggressive patterns for temporary files at any level
- **Git Cleanup**: Comprehensive cleanup of tracked temporary files using `git rm --cached` and `find` commands
- **Business Context**: Changed from "optional" to "mandatory" MCP tool usage in prompts
- **Setup Configuration**: Fixed `setup.rb` to include `mcp__atlassian` permission in command template

### Fixed
- **Temporary File Commits**: Prevents `tmp/`, `log/`, `storage/`, `coverage/` directories from being committed
- **MCP Tool Access**: Fixed missing `mcp__atlassian` permission in setup script
- **Syntax Error**: Removed stray `y` character that caused Ruby syntax errors
- **Method Missing**: Added missing `extract_file_path_from_error` method to `HealingJob` class

## [0.1.23] - 2025-08-27

### Added
- **Persistent Isolated Workspaces**: Implemented persistent workspaces that reuse the same isolated environment instead of cloning each time
- **Smart Branch Checkout**: Workspaces now checkout to the configured target branch instead of cloning the current working branch
- **Workspace Reset**: Added ability to reset workspace to clean state without deleting the entire workspace
- **Configuration Control**: Added `persistent_workspaces` and `sticky_workspace` configuration options

### Changed
- **Workspace Strategy**: Changed from cloning new workspaces each time to reusing persistent workspaces with branch checkout
- **Performance**: Significantly faster healing operations by avoiding repeated repository cloning
- **Branch Targeting**: Workspaces now target the configured `pr_target_branch` instead of the current working branch

### Fixed
- **Branch Consistency**: Ensures fixes are always applied to the correct target branch regardless of current working branch

## [0.1.22] - 2025-08-27

### Fixed
- **Critical Flag Fix**: Fixed Claude Terminal command to use correct `--print` flag instead of unsupported `--code` flag
- **Command Compatibility**: Ensured all Claude Terminal flags are compatible with the `--print` command
- **Fallback Template**: Updated fallback command template to use correct flags

## [0.1.21] - 2025-08-27

### Fixed
- **Critical Bug Fix**: Resolved `mcp_setup` undefined method error in Claude Code evolution handler
- **Claude Command Fix**: Fixed command template to use `--print` instead of `--code` for proper code editing
- **Demo Mode Enhancement**: Improved demo mode handling with optimized Claude command building
- **Command Cleanup**: Removed duplicate permission flags and incompatible command options

## [0.1.20] - 2025-08-27

### Added
- **Confluence MCP Integration**: Added direct Confluence MCP tools for business context fetching (optional usage)
- **Flexible MCP Usage**: Enhanced prompts to optionally use Confluence MCP tools when available
- **Non-interactive MCP**: Fixed Claude Terminal flags to avoid manual approval prompts
- **Business Context Strategy**: Added `confluence_only` strategy for focused Confluence documentation usage

### Fixed
- **MCP Tool Access**: Removed restrictive tool flags that blocked MCP tool usage
- **Debug Logging**: Cleaned up unnecessary MCP debugging logs from initialization and job startup
- **Command Optimization**: Fixed Claude Terminal command flags for proper MCP integration

### Changed
- **Prompt Strategy**: Updated business context prompts to optionally use MCP tools when available
- **Initialization**: Streamlined gem startup without MCP availability checks
- **Dependencies**: Maintained `httparty` for MCP API integration while removing debug overhead

## [0.1.19] - 2025-08-21

### Fixed
- **Critical Git Operations Duplication**: Fixed duplicate Git operations between evolution handler and workspace manager.
- **Branch Detection**: Fixed automatic detection of repository's default branch (master vs main).
- **Configuration Loading**: Fixed pr_target_branch configuration loading from both git section and root level.
- **Workspace Isolation**: Improved Git operations to occur only in isolated workspace, preventing conflicts.

### Changed
- **Evolution Handler**: Removed duplicate Git operations to prevent conflicts with workspace manager.
- **Setup Script**: Enhanced with automatic branch detection and better configuration structure.

## [0.1.18] - 2025-08-21

### Fixed
- **Critical YAML Generation Bug**: Fixed incorrect indentation in setup script that caused YAML parsing errors.
- **Configuration File Structure**: Corrected all YAML indentation issues in generated configuration files.

## [0.1.17] - 2025-08-21

### Added
- **Interactive Demo Mode Setup**: Added comprehensive demo mode configuration options to the interactive setup script.
- **Demo Mode Features**: Timeout reduction (60s), sticky workspace, Claude session persistence, and conditional test/PR skipping.
- **Setup Script Enhancements**: Better user guidance for demo mode configuration and performance optimization.

### Changed
- **Setup Script**: Enhanced with demo mode questions and configuration generation.
- **Configuration Generation**: Automatically generates optimized settings for conference demonstrations.

## [0.1.16] - 2025-08-21

### Added
- Processing state: dashboard shows in-flight healings as "processing" (no longer treated as failed)
- API metrics payload now includes `status` and timezone-aware `created_at`

### Changed
- API endpoints default to JSON (`/code_healer/api/...`) to avoid template lookup
- Compact metrics JSON for dashboard list rendering

### Fixed
- Timezone correctness: all metrics timestamps use `Time.zone`
- Daily trend counts computed with timezone-aware day buckets

## [0.1.15] - 2025-08-21

### Fixed
- **Dashboard Template Loading**: Fixed template loading issues by explicitly specifying view paths
- **Engine Views Configuration**: Properly configured engine views path to resolve template missing errors
- **Controller Template Rendering**: Updated render calls to use explicit template paths

### Changed
- **Template Rendering**: Changed from implicit template rendering to explicit template path specification
- **View Path Configuration**: Enhanced engine configuration for proper view loading

## [0.1.14] - 2025-08-21

### Added
- **Dashboard UI Improvements**: Enhanced dashboard with proper HTML layout and styling
- **Charts and Visualizations**: Added Chart.js integration for data visualization
- **Detailed Views**: Enhanced healing details and performance metrics views
- **Responsive Design**: Mobile-friendly dashboard interface

### Fixed
- **SQL Compatibility**: Replaced raw SQL with Rails-native methods for better database compatibility
- **Dashboard Controller**: Fixed controller loading and routing issues
- **Engine Integration**: Simplified engine structure to avoid conflicts

### Changed
- **Metrics Collection**: Improved performance of dashboard metrics queries
- **UI Rendering**: Replaced plain text dashboard with proper HTML views

## [0.1.13] - 2025-08-21

### Added
- **Automatic Dashboard Integration**: Rails Engine automatically mounts dashboard routes
- **Database Migrations**: Automatic migration copying and execution
- **Dashboard Components**: Complete dashboard system with metrics, trends, and performance views
- **API Endpoints**: JSON API for dashboard data integration

### Fixed
- **Git Operations**: All Git operations now occur within isolated healing workspaces
- **PR Creation**: Fixed duplicate PR creation and repository targeting issues
- **Workspace Management**: Improved isolated healing environment with proper cleanup

### Changed
- **Healing Workflow**: Complete isolation of healing operations from main repository
- **Dashboard Installation**: Fully automatic dashboard setup via Rails Engine

## [0.1.12] - 2025-08-20

### Fixed
- **Duplicate PR Creation**: Prevented duplicate PR creation when evolution handler already creates PRs
- **Workspace Cleanup**: Improved cleanup of healing workspaces

## [0.1.11] - 2025-08-20

### Fixed
- **Repository Cloning**: Fixed incorrect repository cloning by using GitHub remote URL instead of local path
- **Git Remote**: Ensured workspace has correct remote origin for proper Git operations

## [0.1.10] - 2025-08-20

### Changed
- **Git Operations**: All Git operations (branching, committing, pushing, PR creation) now occur strictly within isolated workspace
- **File Operations**: Removed direct file copying to main repository for complete isolation

## [0.1.9] - 2025-08-20

### Fixed
- **Git Commit Issues**: Added proper change detection before committing in isolated workspace
- **File Comparison**: Enhanced file comparison logic to only copy changed files

## [0.1.8] - 2025-08-20

### Fixed
- **Workspace Cleanup**: Improved cleanup process to prevent Git conflicts

## [0.1.7] - 2025-08-20

### Fixed
- **Git Working Tree**: Preserved .git directory during cloning and only removed during cleanup

## [0.1.6] - 2025-08-20

### Fixed
- **Branch Name Sanitization**: Improved branch name handling for Git operations

## [0.1.5] - 2025-08-20

### Fixed
- **Duplicate Class Definition**: Removed duplicate HealingJob class definition causing Sidekiq errors

## [0.1.4] - 2025-08-20

### Fixed
- **Workspace Logging**: Added comprehensive logging to isolated healing workspace system

## [0.1.3] - 2025-08-20

### Fixed
- **Configuration Keys**: Updated HealingWorkspaceManager to handle both string and symbol keys

## [0.1.2] - 2025-08-20

### Fixed
- **Git Operations**: Fixed Git operations in isolated healing workspaces

## [0.1.1] - 2025-08-20

### Fixed
- **Production Safety**: Enhanced production safety with isolated healing workspaces
- **Git Integration**: Improved Git integration within isolated environments

## [0.1.0] - 2025-08-20

### Added
- **AI-Powered Code Healing**: Automatic code error detection and repair
- **Multiple AI Providers**: Support for OpenAI API and Claude Code Terminal
- **Business Context Integration**: MCP-powered intelligent healing with business rules
- **Git Integration**: Automatic branch creation, commits, and pull requests
- **Isolated Healing**: Safe code modification in isolated workspaces
- **Dashboard System**: Metrics collection and visualization
- **Rails Integration**: Automatic Rails application integration via Railtie

---

## Version History

- **0.1.0**: Initial gem release with core functionality
- **Unreleased**: Future improvements and features

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.txt) file for details.
