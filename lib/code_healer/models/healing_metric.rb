module CodeHealer
  class HealingMetric < ActiveRecord::Base
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
        # Timezone-aware daily buckets using application time zone
        start_date = days.days.ago.to_date
        end_date = Time.zone.today

        trend_data = {}
        (start_date..end_date).each do |date|
          day_start = Time.zone.parse(date.to_s).beginning_of_day
          day_end   = day_start.end_of_day
          count = where(created_at: day_start..day_end).count
          trend_data[date.strftime('%Y-%m-%d')] = count
        end
        trend_data
      end
      
      def hourly_healing_distribution
        # Use Rails to group by hour without raw SQL
        distribution = {}
        (0..23).each do |hour|
          start_time = Time.current.beginning_of_day + hour.hours
          end_time = start_time + 1.hour
          count = where(created_at: start_time..end_time).count
          distribution[hour.to_s.rjust(2, '0')] = count
        end
        distribution
      end
    end
    
    # Instance methods
    def processing?
      healing_completed_at.nil?
    end

    def display_status
      return 'processing' if processing?
      healing_successful ? 'success' : 'failed'
    end
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
      return '⏳ Processing' if processing?
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
