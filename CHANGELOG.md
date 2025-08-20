# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.12] - 2025-01-14

### Fixed
- **Duplicate PR creation** - Prevents duplicate pull requests when evolution handler already creates one
- **PR workflow optimization** - Skips redundant PR creation in healing workspace manager

## [0.1.11] - 2025-01-14

### Fixed
- **Repository cloning** - Now clones from GitHub remote URL instead of local path
- **Git remote configuration** - Ensures workspace has correct GitHub remote for PR creation
- **Debug information** - Added Git remote and branch debugging in workspace operations

## [0.1.10] - 2025-01-14

### Changed
- **Complete workspace isolation** - All Git operations now happen in isolated workspace only
- **No file copying** - Removed file copying between workspace and main repo
- **Direct PR creation** - Pull requests are created directly from the isolated workspace
- **Main repo protection** - Main repository is never touched, only the isolated workspace

### Fixed
- **Git commit workflow** - Added proper change detection before committing
- **Empty branch prevention** - Delete healing branches when no changes are detected
- **Enhanced debugging** - Added Git status and diff logging throughout the process

## [0.1.8] - 2025-01-14

### Changed
- **Production safety** - Healing workspace no longer modifies main directory directly
- **Git workflow** - Changes are applied to isolated healing branches only
- **Pull request automation** - Automatic PR creation when configured
- **Method renaming** - `merge_fixes_back` → `create_healing_branch` for clarity

### Fixed
- **Git operations in isolated healing workspace** - Preserved .git directory during cloning for proper Git operations
- **Branch creation and commit operations** now work correctly in the isolated workspace
- **Workspace cleanup** properly removes .git directory to prevent conflicts

## [0.1.6] - 2025-01-14

### Added
- **Code heal directory permission validation** during interactive setup
- **Repository access testing** to ensure the directory can clone and push to the target repo
- **Write permission verification** for the code heal directory
- **Automatic directory creation** if it doesn't exist
- **Comprehensive error messages** with troubleshooting tips for permission issues

### Fixed
- **Duplicate HealingJob class definition** that was preventing isolated healing workspace system from working
- **Class loading conflict** between old and new healing logic
- **Isolated healing workspace system** now properly activated

## [0.1.4] - 2025-01-14

### Added
- **Comprehensive logging** for isolated healing workspace system
- **Detailed workspace creation logs** showing each step of the process
- **Clone operation logging** with success/failure status
- **Fix application logging** in isolated environment
- **Workspace cleanup logging** for debugging

### Fixed
- **Workspace configuration reading** to handle both string and symbol keys
- **Branch name sanitization** to prevent invalid Git branch names

## [0.1.3] - 2025-01-14

### Added
- **Future Plans & Roadmap section** to README
- Jira integration plans for business context automation
- Confluence docs integration for domain knowledge extraction
- PRD parsing capabilities for feature specifications
- Git commit message analysis for business context learning
- Slack/Teams integration for business discussions capture
- Intelligent context discovery from existing code patterns

## [0.1.2] - 2025-01-14

### Changed
- **Final README improvements and personalization**
- Updated contact email to deepan.ppgit@gmail.com
- Added LinkedIn profile link for professional networking
- Enhanced acknowledgments to include Claude AI
- Personalized team references to Deepan Kumar
- Added personal signature with LinkedIn link

## [0.1.1] - 2025-01-14

### Changed
- **Significantly improved README documentation**
- Enhanced setup instructions with interactive bash script guidance
- Added comprehensive configuration explanations for all 50+ options
- Included detailed markdown file creation guide for business context
- Added best practices and troubleshooting sections
- Improved installation and configuration examples
- Enhanced advanced configuration strategies documentation

### Fixed
- Updated repository URLs in gemspec to point to correct GitHub repo
- Fixed executable path configuration in gemspec

## [Unreleased]

### Added
- Initial gem release
- AI-powered error analysis and code generation
- Multiple healing strategies (API, Claude Code, Hybrid)
- Business context awareness and integration
- Automated Git operations and PR creation
- Background job processing with Sidekiq
- Comprehensive YAML configuration
- Business requirements integration from markdown files
- Rails integration via Railtie

### Changed
- Converted from standalone Rails application to gem
- Refactored for modular architecture
- Improved error handling and logging
- Renamed from CodeHealer to CodeHealer

### Deprecated
- None

### Removed
- None

### Fixed
- Business context loading from markdown files
- Template placeholder substitution in PR creation
- Sidekiq job serialization issues

### Security
- Class restriction system for security
- Environment variable support for sensitive data
- Business rule validation

## [0.1.0] - 2025-01-13

### Added
- Initial release of CodeHealer gem
- Core healing engine
- OpenAI API integration
- Claude Code terminal integration
- Business context management
- Git operations automation
- Sidekiq background processing
- Comprehensive documentation
- Example configurations
- Test suite setup

---

## Version History

- **0.1.0**: Initial gem release with core functionality
- **Unreleased**: Future improvements and features

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.txt) file for details.
