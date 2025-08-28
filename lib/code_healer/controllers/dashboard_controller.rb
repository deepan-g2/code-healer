module CodeHealer
  class DashboardController < ActionController::Base
    # Set the view path to look in the engine's views directory
    self.view_paths = ["#{CodeHealer::Engine.root}/lib/code_healer/views"]
    
    def index
      @summary = MetricsCollector.dashboard_summary
      @recent_healings = HealingMetric.order(created_at: :desc).limit(10)
      
      respond_to do |format|
        format.html { render template: "dashboard/index" }
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
      @metrics = @metrics.limit(params[:limit].to_i) if params[:limit].present?
      
      # Render compact JSON suitable for dashboard list
      payload = @metrics.map do |m|
        {
          healing_id: m.healing_id,
          class_name: m.class_name,
          method_name: m.method_name,
          error_class: m.error_class,
          error_message: m.error_message,
          healing_successful: m.healing_successful,
          status: m.display_status,
          created_at: m.created_at.in_time_zone(Time.zone),
          healing_branch: m.healing_branch,
          pull_request_url: m.pull_request_url
        }
      end

      respond_to do |format|
        format.json { render json: payload }
        format.any  { render json: payload }
      end
    end
    
    def healing_details
      @healing = HealingMetric.find_by(healing_id: params[:healing_id])
      
      respond_to do |format|
        format.html { render template: "dashboard/healing_details" }
        format.json do
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
        format.any do
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
    
    def summary
      render json: MetricsCollector.dashboard_summary
    end
  end
end
