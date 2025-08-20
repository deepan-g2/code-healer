module CodeHealer
  class DashboardController < ApplicationController
    def index
      @summary = MetricsCollector.dashboard_summary
      @recent_healings = HealingMetric.order(created_at: :desc).limit(10)
      
      respond_to do |format|
        format.html { render_dashboard }
        format.json { render json: @summary }
      end
    end
    
    def metrics
      @metrics = HealingMetric.order(created_at: :desc)
      
      # Apply filters
      @metrics = @metrics.by_class(params[:class_name]) if params[:class_name].present?
      @metrics = @metrics.by_evolution_method(params[:evolution_method]) if params[:evolution_method].present?
      @metrics = @metrics.by_ai_provider(params[:ai_provider]) if params[:ai_provider].present?
      @metrics = @metrics.recent(params[:days].to_i) if params[:days].present?
      
      respond_to do |format|
        format.html { render :metrics }
        format.json { render json: @metrics }
      end
    end
    
    def healing_details
      @healing = HealingMetric.find_by(healing_id: params[:healing_id])
      
      if @healing
        render json: {
          healing: @healing,
          timing: {
            total_duration: @healing.duration_seconds,
            ai_processing: @healing.ai_processing_seconds,
            git_operations: @healing.git_operations_seconds
          },
          status: {
            success: @healing.success_status,
            evolution_method: @healing.evolution_method_display,
            ai_provider: @healing.ai_provider_display
          }
        }
      else
        render json: { error: 'Healing not found' }, status: :not_found
      end
    end
    
    def trends
      days = params[:days]&.to_i || 30
      
      trends = {
        daily: HealingMetric.daily_healing_trend(days),
        hourly: HealingMetric.hourly_healing_distribution,
        evolution_methods: HealingMetric.evolution_method_distribution,
        ai_providers: HealingMetric.ai_provider_distribution,
        error_classes: HealingMetric.top_error_classes(10),
        classes_healed: HealingMetric.top_classes_healed(10)
      }
      
      render json: trends
    end
    
    def performance
      performance_data = {
        average_resolution_time: HealingMetric.average_resolution_time,
        success_rate: HealingMetric.success_rate,
        ai_success_rate: HealingMetric.where(ai_success: true).count.to_f / HealingMetric.count * 100,
        test_pass_rate: HealingMetric.where(tests_passed: true).count.to_f / HealingMetric.count * 100,
        syntax_valid_rate: HealingMetric.where(syntax_valid: true).count.to_f / HealingMetric.count * 100
      }
      
      render json: performance_data
    end
    
    private
    
    def render_dashboard
      # This will be replaced with actual dashboard view
      render plain: "CodeHealer Dashboard - Coming Soon!\n\n" \
                    "Total Healings: #{@summary[:total_healings]}\n" \
                    "Success Rate: #{@summary[:success_rate]}%\n" \
                    "Healings Today: #{@summary[:healings_today]}\n" \
                    "Healings This Week: #{@summary[:healings_this_week]}"
    end
  end
end
