class CreateHealingMetrics < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :healing_metrics do |t|
      # Basic healing info
      t.string :healing_id, null: false, index: true
      t.string :class_name, null: false
      t.string :method_name, null: false
      t.string :error_class, null: false
      t.text :error_message
      t.string :file_path
      
      # AI and evolution details
      t.string :evolution_method # claude_code_terminal, api, hybrid
      t.string :ai_provider # claude, openai
      t.boolean :ai_success, default: false
      t.text :ai_response
      t.integer :ai_tokens_used
      t.decimal :ai_cost, precision: 10, scale: 4
      
      # Workspace and Git details
      t.string :workspace_path
      t.string :healing_branch
      t.string :pull_request_url
      t.boolean :pr_created, default: false
      
      # Timing and performance
      t.datetime :error_occurred_at
      t.datetime :healing_started_at
      t.datetime :healing_completed_at
      t.integer :total_duration_ms
      t.integer :ai_processing_time_ms
      t.integer :git_operations_time_ms
      
      # Success metrics
      t.boolean :healing_successful, default: false
      t.boolean :tests_passed, default: false
      t.boolean :syntax_valid, default: false
      t.text :failure_reason
      
      # Business context
      t.text :business_context_used
      t.string :jira_issue_id
      t.string :confluence_page_id
      
      # Metadata
      t.json :additional_metadata
      t.timestamps
    end
    
    # Indexes for performance
    add_index :healing_metrics, [:class_name, :method_name]
    add_index :healing_metrics, [:evolution_method, :ai_provider]
    add_index :healing_metrics, [:healing_successful, :created_at]
    add_index :healing_metrics, :created_at
  end
end
