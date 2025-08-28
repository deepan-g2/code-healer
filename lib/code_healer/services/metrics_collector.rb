module CodeHealer
  class MetricsCollector
    def self.track_healing_start(healing_id, class_name, method_name, error_class, error_message, file_path)
      metric = HealingMetric.find_or_initialize_by(healing_id: healing_id)
      
      metric.assign_attributes(
        class_name: class_name,
        method_name: method_name,
        error_class: error_class,
        error_message: error_message,
        file_path: file_path,
        healing_started_at: Time.zone.now
      )
      
      metric.save!
      metric
    end
    
    def self.track_ai_processing(healing_id, evolution_method, ai_provider, ai_response, tokens_used = nil, cost = nil)
      metric = HealingMetric.find_by(healing_id: healing_id)
      return unless metric
      
      metric.update!(
        evolution_method: evolution_method,
        ai_provider: ai_provider,
        ai_response: ai_response,
        ai_tokens_used: tokens_used,
        ai_cost: cost,
        ai_success: true
      )
    end
    
    def self.track_ai_failure(healing_id, evolution_method, ai_provider, failure_reason)
      metric = HealingMetric.find_by(healing_id: healing_id)
      return unless metric
      
      metric.update!(
        evolution_method: evolution_method,
        ai_provider: ai_provider,
        ai_success: false,
        failure_reason: failure_reason
      )
    end
    
    def self.track_workspace_creation(healing_id, workspace_path)
      metric = HealingMetric.find_by(healing_id: healing_id)
      return unless metric
      
      metric.update!(workspace_path: workspace_path)
    end
    
    def self.track_git_operations(healing_id, healing_branch, pull_request_url, pr_created)
      metric = HealingMetric.find_by(healing_id: healing_id)
      return unless metric
      
      metric.update!(
        healing_branch: healing_branch,
        pull_request_url: pull_request_url,
        pr_created: pr_created
      )
    end
    
    def self.track_healing_completion(healing_id, success, tests_passed, syntax_valid, failure_reason = nil)
      metric = HealingMetric.find_by(healing_id: healing_id)
      return unless metric
      
      # Calculate timing
      total_duration = if metric.healing_started_at
        ((Time.zone.now - metric.healing_started_at) * 1000).round
      else
        nil
      end
      
      metric.update!(
        healing_completed_at: Time.zone.now,
        total_duration_ms: total_duration,
        healing_successful: success,
        tests_passed: tests_passed,
        syntax_valid: syntax_valid,
        failure_reason: failure_reason
      )
    end
    
    def self.track_timing(healing_id, ai_processing_time_ms, git_operations_time_ms)
      metric = HealingMetric.find_by(healing_id: healing_id)
      return unless metric
      
      metric.update!(
        ai_processing_time_ms: ai_processing_time_ms,
        git_operations_time_ms: git_operations_time_ms
      )
    end
    
    def self.track_business_context(healing_id, business_context, jira_issue_id = nil, confluence_page_id = nil)
      metric = HealingMetric.find_by(healing_id: healing_id)
      return unless metric
      
      metric.update!(
        business_context_used: business_context,
        jira_issue_id: jira_issue_id,
        confluence_page_id: confluence_page_id
      )
    end
    
    def self.track_error_occurrence(healing_id, error_occurred_at)
      metric = HealingMetric.find_by(healing_id: healing_id)
      return unless metric
      
      metric.update!(error_occurred_at: error_occurred_at.in_time_zone(Time.zone))
    end
    
    # Generate unique healing ID
    def self.generate_healing_id
      "healing_#{Time.current.to_i}_#{SecureRandom.hex(8)}"
    end
    
    # Get dashboard summary
    def self.dashboard_summary
      {
        total_healings: HealingMetric.total_healings,
        success_rate: HealingMetric.success_rate,
        healings_today: HealingMetric.healings_today,
        healings_this_week: HealingMetric.healings_this_week,
        healings_this_month: HealingMetric.healings_this_month,
        average_resolution_time: HealingMetric.average_resolution_time,
        evolution_methods: HealingMetric.evolution_method_distribution,
        ai_providers: HealingMetric.ai_provider_distribution,
        top_error_classes: HealingMetric.top_error_classes(5),
        top_classes_healed: HealingMetric.top_classes_healed(5),
        daily_trend: HealingMetric.daily_healing_trend(7),
        hourly_distribution: HealingMetric.hourly_healing_distribution
      }
    end
  end
end
