# frozen_string_literal: true

require_relative "lib/code_healer/version"

Gem::Specification.new do |spec|
  spec.name = "code_healer"
  spec.version = CodeHealer::VERSION
  spec.authors = ["Deepan Kumar"]
  spec.email = ["deepan.ppgit@gmail.com"]

  spec.summary = "AI-powered code healing and self-repair system for Ruby applications"
  spec.description = <<~DESC
    CodeHealer is a revolutionary gem that enables your Ruby applications to 
    automatically detect, analyze, and fix errors using AI. It integrates 
    with OpenAI API, Claude Code terminal, and provides intelligent error handling, 
    business context awareness, and automated Git operations.
    
    Features:
    - 🤖 AI-powered error analysis and code generation
    - 🎯 Business context-aware fixes
    - 🔄 Multiple healing strategies (API, Claude Code, Hybrid)
    - 📝 Automated Git operations and PR creation
    - 📋 Business requirements integration from markdown
    - ⚡ Background job processing with Sidekiq
    - 🎨 Configurable via YAML files
  DESC
  
  spec.homepage = "https://github.com/deepan-g2/code-healer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = "https://github.com/deepan-g2/code-healer"
  spec.metadata["source_code_uri"] = "https://github.com/deepan-g2/code-healer"
  spec.metadata["changelog_uri"] = "https://github.com/deepan-g2/code-healer/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/deepan-g2/code-healer/issues"
  spec.metadata["documentation_uri"] = "https://github.com/deepan-g2/code-healer/blob/main/README.md"

  # Specify which files should be added to the gem when it is released
  spec.files = Dir[
    "lib/**/*",
    "bin/**/*",
    "config/**/*",
    "docs/**/*",
    "examples/**/*",
    "*.md",
    "code_healer.gemspec"
  ]
  
  spec.require_paths = ["lib"]
  spec.bindir = "exe"
  spec.executables = ["code_healer-setup"]

  # Runtime dependencies
  spec.add_runtime_dependency 'rails', '>= 6.0.0'
  spec.add_runtime_dependency 'sidekiq', '>= 6.0.0'
  spec.add_runtime_dependency 'redis', '~> 4.0', '>= 4.0.0'
  spec.add_runtime_dependency 'octokit', '~> 4.0', '>= 4.0.0'
  spec.add_runtime_dependency 'git', '~> 1.0', '>= 1.0.0'
  spec.add_runtime_dependency 'openai', '~> 0.16.0', '>= 0.16.0'
  spec.add_runtime_dependency 'activesupport', '>= 6.0.0'
  spec.add_runtime_dependency 'actionpack', '>= 6.0.0'
  spec.add_runtime_dependency 'activemodel', '>= 6.0.0'
  spec.add_runtime_dependency 'httparty', '~> 0.21.0', '>= 0.21.0'


  # Development dependencies
  spec.add_development_dependency "bundler", ">= 2.0.0"
  spec.add_development_dependency "rake", ">= 13.0.0"
  spec.add_development_dependency "rspec", ">= 3.0.0"
  spec.add_development_dependency "rspec-rails", ">= 5.0.0"
  spec.add_development_dependency "factory_bot_rails", ">= 6.0.0"
  spec.add_development_dependency "faker", ">= 2.0.0"
  spec.add_development_dependency "webmock", ">= 3.0.0"
  spec.add_development_dependency "vcr", ">= 6.0.0"
  spec.add_development_dependency "rubocop", ">= 1.0.0"
  spec.add_development_dependency "rubocop-rails", ">= 2.0.0"
  spec.add_development_dependency "yard", ">= 0.9.0"
  spec.add_development_dependency "redcarpet", ">= 3.0.0"
end
