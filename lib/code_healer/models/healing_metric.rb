module CodeHealer
  class HealingMetric < ApplicationRecord
    self.table_name = 'healing_metrics'
    
    # Validations
    validates :healing_id, presence: true, uniqueness: true
    validates :class_name, presence: true
    validates :method_name, presence: true
    validates :error_class, presence: true
    
    # Scopes for common queries
    scope :successful, -> { where(healing_successful: true) }
    scope :failed, -> { where(healing_successful: false) }
    scope :recent, ->(days = 30) { where('created_at >= ?', days.days.ago) }
    scope :by_evolution_method, ->(method) { where(evolution_method: method) }
    scope :by_ai_provider, ->(provider) { where(ai_provider: provider) }
    scope :by_class, ->(class_name) { where(class_name: class_name) }
    
    # Class methods for dashboard metrics
    class << self
      def total_healings
        count
      end
      
      def success_rate
        return 0 if count.zero?
        (successful.count.to_f / count * 100).round(2)
      end
      
      def healings_today
        where('created_at >= ?', Date.current.beginning_of_day).count
      end
      
      def healings_this_week
        where('created_at >= ?', Date.current.beginning_of_week).count
      end
      
      def healings_this_month
        where('created_at >= ?', Date.current.beginning_of_month).count
      end
      
      def average_resolution_time
        successful.where.not(total_duration_ms: nil).average(:total_duration_ms)&.round(2)
      end
      
      def evolution_method_distribution
        group(:evolution_method).count
      end
      
      def ai_provider_distribution
        group(:ai_provider).count
      end
      
      def top_error_classes(limit = 10)
        group(:error_class).order('count_all DESC').limit(limit).count
      end
      
      def top_classes_healed(limit = 10)
        group(:class_name).order('count_all DESC').limit(limit).count
      end
      
      def daily_healing_trend(days = 30)
        where('created_at >= ?', days.days.ago)
          .group("DATE(created_at)")
          .order("DATE(created_at)")
          .count
      end
      
      def hourly_healing_distribution
        group("EXTRACT(HOUR FROM created_at)").order("EXTRACT(HOUR FROM created_at)").count
      end
    end
    
    # Instance methods
    def duration_seconds
      return nil unless total_duration_ms
      (total_duration_ms / 1000.0).round(2)
    end
    
    def ai_processing_seconds
      return nil unless ai_processing_time_ms
      (ai_processing_time_ms / 1000.0).round(2)
    end
    
    def git_operations_seconds
      return nil unless git_operations_time_ms
      (git_operations_time_ms / 1000.0).round(2)
    end
    
    def success_status
      healing_successful ? '✅ Success' : '❌ Failed'
    end
    
    def evolution_method_display
      evolution_method&.titleize || 'Unknown'
    end
    
    def ai_provider_display
      ai_provider&.titleize || 'Unknown'
    end
  end
end
