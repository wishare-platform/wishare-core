# Mobile A/B Testing Service for Wishare
# Comprehensive experimentation framework for mobile apps
class MobileABTestingService
  include ActiveSupport::Benchmarkable

  # Experiment status
  EXPERIMENT_STATUSES = %w[draft active paused completed archived].freeze

  # Statistical confidence levels
  CONFIDENCE_LEVELS = {
    low: 0.90,
    medium: 0.95,
    high: 0.99
  }.freeze

  class << self
    # Get variant for user in specific experiment
    def get_variant(experiment_key, user_id, context = {})
      experiment = find_active_experiment(experiment_key)
      return default_variant(experiment_key) unless experiment

      # Check if user is in experiment
      assignment = get_or_create_assignment(experiment, user_id, context)

      variant = assignment&.variant || default_variant(experiment_key)

      # Track exposure event
      track_exposure(experiment, user_id, variant, context)

      {
        experiment: experiment_key,
        variant: variant,
        experiment_id: experiment.id,
        assignment_id: assignment&.id
      }
    end

    # Track conversion event for experiment
    def track_conversion(experiment_key, user_id, conversion_type = 'default', value = nil, context = {})
      experiment = find_active_experiment(experiment_key)
      return false unless experiment

      assignment = find_assignment(experiment, user_id)
      return false unless assignment

      # Create conversion record
      conversion = create_conversion_record(
        experiment: experiment,
        assignment: assignment,
        user_id: user_id,
        conversion_type: conversion_type,
        value: value,
        context: context
      )

      # Update real-time metrics
      update_conversion_metrics(experiment, assignment.variant, conversion_type, value)

      conversion
    end

    # Create new A/B test experiment
    def create_experiment(experiment_data)
      experiment = ABTestExperiment.create!(
        key: experiment_data[:key],
        name: experiment_data[:name],
        description: experiment_data[:description],
        hypothesis: experiment_data[:hypothesis],
        variants: experiment_data[:variants],
        traffic_allocation: experiment_data[:traffic_allocation] || 100,
        platform_targeting: experiment_data[:platform_targeting] || %w[ios android],
        user_targeting: experiment_data[:user_targeting] || {},
        primary_metric: experiment_data[:primary_metric],
        secondary_metrics: experiment_data[:secondary_metrics] || [],
        minimum_sample_size: experiment_data[:minimum_sample_size] || 1000,
        confidence_level: experiment_data[:confidence_level] || 'medium',
        max_duration_days: experiment_data[:max_duration_days] || 30,
        status: 'draft',
        created_by: experiment_data[:created_by]
      )

      # Set up experiment tracking
      setup_experiment_tracking(experiment)

      experiment
    end

    # Start experiment
    def start_experiment(experiment_id)
      experiment = ABTestExperiment.find(experiment_id)

      validate_experiment_for_start(experiment)

      experiment.update!(
        status: 'active',
        started_at: Time.current
      )

      # Initialize metrics tracking
      initialize_experiment_metrics(experiment)

      # Send notification
      notify_experiment_started(experiment)

      experiment
    end

    # Stop experiment
    def stop_experiment(experiment_id, reason = nil)
      experiment = ABTestExperiment.find(experiment_id)

      experiment.update!(
        status: 'completed',
        completed_at: Time.current,
        completion_reason: reason
      )

      # Calculate final results
      results = calculate_experiment_results(experiment)

      # Send results notification
      notify_experiment_completed(experiment, results)

      results
    end

    # Get experiment results and analysis
    def get_experiment_results(experiment_id)
      experiment = ABTestExperiment.find(experiment_id)

      {
        experiment: experiment_summary(experiment),
        assignments: assignment_summary(experiment),
        conversions: conversion_summary(experiment),
        statistical_analysis: statistical_analysis(experiment),
        recommendations: generate_recommendations(experiment)
      }
    end

    # Get all active experiments for mobile platforms
    def get_active_mobile_experiments(platform = nil, user_context = {})
      experiments = ABTestExperiment.active

      experiments = experiments.where("platform_targeting @> ?", [platform].to_json) if platform
      experiments = filter_by_user_targeting(experiments, user_context) if user_context.any?

      experiments.map do |experiment|
        {
          key: experiment.key,
          name: experiment.name,
          variants: experiment.variants,
          traffic_allocation: experiment.traffic_allocation
        }
      end
    end

    private

    def find_active_experiment(experiment_key)
      ABTestExperiment.active.find_by(key: experiment_key)
    end

    def get_or_create_assignment(experiment, user_id, context)
      # Check for existing assignment
      assignment = find_assignment(experiment, user_id)
      return assignment if assignment

      # Check if user qualifies for experiment
      return nil unless user_qualifies_for_experiment?(experiment, user_id, context)

      # Check traffic allocation
      return nil unless user_in_traffic_allocation?(experiment, user_id)

      # Assign variant
      variant = assign_variant(experiment, user_id)

      # Create assignment record
      create_assignment_record(experiment, user_id, variant, context)
    end

    def find_assignment(experiment, user_id)
      ABTestAssignment.find_by(experiment: experiment, user_id: user_id)
    end

    def user_qualifies_for_experiment?(experiment, user_id, context)
      targeting = experiment.user_targeting

      # Check platform targeting
      if targeting['platforms'].present?
        platform = context[:platform] || extract_platform_from_context(context)
        return false unless targeting['platforms'].include?(platform)
      end

      # Check user segment targeting
      if targeting['user_segments'].present?
        user_segment = get_user_segment(user_id)
        return false unless targeting['user_segments'].include?(user_segment)
      end

      # Check app version targeting
      if targeting['app_versions'].present?
        app_version = context[:app_version]
        return false unless version_matches?(app_version, targeting['app_versions'])
      end

      # Check geographic targeting
      if targeting['countries'].present?
        country = context[:country] || get_user_country(user_id)
        return false unless targeting['countries'].include?(country)
      end

      # Check new user targeting
      if targeting['new_users_only'] == true
        return false unless is_new_user?(user_id)
      end

      true
    end

    def user_in_traffic_allocation?(experiment, user_id)
      # Use consistent hashing to determine if user is in traffic allocation
      hash_input = "#{experiment.key}:#{user_id}"
      hash_value = Digest::MD5.hexdigest(hash_input).to_i(16)
      bucket = hash_value % 100

      bucket < experiment.traffic_allocation
    end

    def assign_variant(experiment, user_id)
      variants = experiment.variants

      # Use consistent hashing for variant assignment
      hash_input = "#{experiment.key}:#{user_id}:variant"
      hash_value = Digest::MD5.hexdigest(hash_input).to_i(16)

      # Calculate cumulative weights
      total_weight = variants.sum { |v| v['weight'] || 50 }
      cumulative_weights = []
      running_total = 0

      variants.each do |variant|
        running_total += (variant['weight'] || 50)
        cumulative_weights << {
          variant: variant['key'],
          threshold: (running_total.to_f / total_weight * 100).round
        }
      end

      # Assign based on hash bucket
      bucket = hash_value % 100

      assigned_variant = cumulative_weights.find { |cw| bucket < cw[:threshold] }
      assigned_variant&.dig(:variant) || variants.first['key']
    end

    def create_assignment_record(experiment, user_id, variant, context)
      ABTestAssignment.create!(
        experiment: experiment,
        user_id: user_id,
        variant: variant,
        assigned_at: Time.current,
        platform: context[:platform],
        app_version: context[:app_version],
        user_agent: context[:user_agent],
        country: context[:country],
        device_info: extract_device_info(context)
      )
    end

    def create_conversion_record(experiment:, assignment:, user_id:, conversion_type:, value:, context:)
      ABTestConversion.create!(
        experiment: experiment,
        assignment: assignment,
        user_id: user_id,
        conversion_type: conversion_type,
        value: value,
        converted_at: Time.current,
        platform: context[:platform],
        session_id: context[:session_id],
        context_data: context
      )
    end

    def track_exposure(experiment, user_id, variant, context)
      # Track exposure for analytics
      AnalyticsEvent.create!(
        event_name: 'ab_test_exposure',
        user_id: user_id,
        event_data: {
          experiment_key: experiment.key,
          experiment_id: experiment.id,
          variant: variant,
          platform: context[:platform],
          app_version: context[:app_version]
        },
        platform: 'mobile'
      )

      # Update exposure metrics
      update_exposure_metrics(experiment, variant)
    end

    def update_exposure_metrics(experiment, variant)
      date_key = Date.current.strftime('%Y-%m-%d')

      Redis.current.pipelined do |pipeline|
        pipeline.incr("ab_test:#{experiment.key}:exposures:#{variant}:#{date_key}")
        pipeline.incr("ab_test:#{experiment.key}:total_exposures:#{date_key}")

        # Set expiration (90 days)
        pipeline.expire("ab_test:#{experiment.key}:exposures:#{variant}:#{date_key}", 90.days.to_i)
        pipeline.expire("ab_test:#{experiment.key}:total_exposures:#{date_key}", 90.days.to_i)
      end
    rescue Redis::BaseError => e
      Rails.logger.warn "⚠️ Failed to update exposure metrics: #{e.message}"
    end

    def update_conversion_metrics(experiment, variant, conversion_type, value)
      date_key = Date.current.strftime('%Y-%m-%d')

      Redis.current.pipelined do |pipeline|
        pipeline.incr("ab_test:#{experiment.key}:conversions:#{variant}:#{conversion_type}:#{date_key}")
        pipeline.incr("ab_test:#{experiment.key}:total_conversions:#{conversion_type}:#{date_key}")

        if value
          pipeline.incrbyfloat("ab_test:#{experiment.key}:conversion_value:#{variant}:#{conversion_type}:#{date_key}", value.to_f)
        end

        # Set expiration (90 days)
        pipeline.expire("ab_test:#{experiment.key}:conversions:#{variant}:#{conversion_type}:#{date_key}", 90.days.to_i)
        pipeline.expire("ab_test:#{experiment.key}:total_conversions:#{conversion_type}:#{date_key}", 90.days.to_i)
      end
    rescue Redis::BaseError => e
      Rails.logger.warn "⚠️ Failed to update conversion metrics: #{e.message}"
    end

    def default_variant(experiment_key)
      # Return control variant by default
      'control'
    end

    def setup_experiment_tracking(experiment)
      # Set up tracking infrastructure for the experiment
      Rails.logger.info "🧪 Setting up tracking for experiment: #{experiment.key}"
    end

    def validate_experiment_for_start(experiment)
      errors = []

      errors << "Experiment must have at least 2 variants" if experiment.variants.length < 2
      errors << "Experiment must have traffic allocation > 0" if experiment.traffic_allocation <= 0
      errors << "Experiment must have primary metric defined" if experiment.primary_metric.blank?

      raise ArgumentError, errors.join('; ') if errors.any?
    end

    def initialize_experiment_metrics(experiment)
      # Initialize Redis counters for the experiment
      experiment.variants.each do |variant|
        date_key = Date.current.strftime('%Y-%m-%d')
        Redis.current.set("ab_test:#{experiment.key}:exposures:#{variant['key']}:#{date_key}", 0)
      end
    end

    def notify_experiment_started(experiment)
      SlackNotificationService.send_message(
        channel: '#ab-testing',
        message: "🧪 A/B Test Started: #{experiment.name}",
        details: {
          experiment_key: experiment.key,
          variants: experiment.variants.map { |v| v['key'] }.join(', '),
          traffic_allocation: "#{experiment.traffic_allocation}%",
          expected_duration: "#{experiment.max_duration_days} days"
        }
      )
    end

    def notify_experiment_completed(experiment, results)
      winner = results[:statistical_analysis][:winner]
      confidence = results[:statistical_analysis][:confidence]

      SlackNotificationService.send_message(
        channel: '#ab-testing',
        message: "🏁 A/B Test Completed: #{experiment.name}",
        details: {
          experiment_key: experiment.key,
          winner: winner || 'No significant winner',
          confidence: confidence ? "#{(confidence * 100).round(2)}%" : 'N/A',
          duration: "#{(experiment.completed_at - experiment.started_at).to_i / 1.day} days"
        }
      )
    end

    def calculate_experiment_results(experiment)
      assignments = experiment.assignments.includes(:conversions)
      conversions = experiment.conversions

      variant_stats = {}

      experiment.variants.each do |variant|
        variant_key = variant['key']
        variant_assignments = assignments.where(variant: variant_key)
        variant_conversions = conversions.joins(:assignment).where(assignments: { variant: variant_key })

        variant_stats[variant_key] = {
          assignments: variant_assignments.count,
          conversions: variant_conversions.count,
          conversion_rate: calculate_conversion_rate(variant_assignments.count, variant_conversions.count),
          total_value: variant_conversions.sum(:value) || 0,
          avg_value_per_conversion: calculate_avg_value(variant_conversions)
        }
      end

      {
        variant_stats: variant_stats,
        statistical_significance: calculate_statistical_significance(variant_stats),
        experiment_summary: experiment_summary(experiment)
      }
    end

    def experiment_summary(experiment)
      {
        id: experiment.id,
        key: experiment.key,
        name: experiment.name,
        status: experiment.status,
        started_at: experiment.started_at,
        completed_at: experiment.completed_at,
        duration_days: experiment.completed_at ? (experiment.completed_at - experiment.started_at).to_i / 1.day : nil,
        variants: experiment.variants,
        traffic_allocation: experiment.traffic_allocation
      }
    end

    def assignment_summary(experiment)
      assignments = experiment.assignments

      {
        total_assignments: assignments.count,
        assignments_by_variant: assignments.group(:variant).count,
        assignments_by_platform: assignments.group(:platform).count,
        assignments_over_time: assignments.group_by_day(:assigned_at).count
      }
    end

    def conversion_summary(experiment)
      conversions = experiment.conversions

      {
        total_conversions: conversions.count,
        conversions_by_variant: conversions.joins(:assignment).group('assignments.variant').count,
        conversions_by_type: conversions.group(:conversion_type).count,
        total_value: conversions.sum(:value) || 0,
        conversions_over_time: conversions.group_by_day(:converted_at).count
      }
    end

    def statistical_analysis(experiment)
      variant_stats = {}
      assignments = experiment.assignments.includes(:conversions)

      experiment.variants.each do |variant|
        variant_key = variant['key']
        variant_assignments = assignments.where(variant: variant_key)
        variant_conversions = variant_assignments.flat_map(&:conversions)

        variant_stats[variant_key] = {
          sample_size: variant_assignments.count,
          conversions: variant_conversions.count,
          conversion_rate: calculate_conversion_rate(variant_assignments.count, variant_conversions.count)
        }
      end

      # Calculate statistical significance between variants
      control_variant = experiment.variants.find { |v| v['key'] == 'control' }&.dig('key') || experiment.variants.first['key']

      significance_results = {}

      experiment.variants.each do |variant|
        variant_key = variant['key']
        next if variant_key == control_variant

        significance = calculate_significance(
          variant_stats[control_variant],
          variant_stats[variant_key]
        )

        significance_results[variant_key] = significance
      end

      {
        variant_stats: variant_stats,
        significance_tests: significance_results,
        winner: determine_winner(significance_results),
        confidence: calculate_overall_confidence(significance_results),
        sample_size_adequate: check_sample_size_adequacy(experiment, variant_stats)
      }
    end

    def generate_recommendations(experiment)
      results = calculate_experiment_results(experiment)
      analysis = statistical_analysis(experiment)

      recommendations = []

      # Check for statistical significance
      if analysis[:winner]
        recommendations << {
          type: 'winner_identified',
          title: "Winner Identified: #{analysis[:winner]}",
          description: "The #{analysis[:winner]} variant shows statistically significant improvement",
          action: 'Implement winning variant',
          priority: 'high'
        }
      else
        recommendations << {
          type: 'no_winner',
          title: "No Clear Winner",
          description: "No variant shows statistically significant improvement over control",
          action: 'Consider running longer or testing different variants',
          priority: 'medium'
        }
      end

      # Check sample size
      unless analysis[:sample_size_adequate]
        recommendations << {
          type: 'insufficient_sample',
          title: "Insufficient Sample Size",
          description: "The experiment may need more data to reach statistical significance",
          action: 'Continue running experiment or increase traffic allocation',
          priority: 'high'
        }
      end

      # Check for early stopping
      if experiment.status == 'active' && should_stop_early?(analysis)
        recommendations << {
          type: 'early_stopping',
          title: "Consider Early Stopping",
          description: "Results show strong significance, consider stopping early",
          action: 'Stop experiment and implement winner',
          priority: 'medium'
        }
      end

      recommendations
    end

    # Helper methods for statistical calculations
    def calculate_conversion_rate(assignments, conversions)
      return 0.0 if assignments.zero?
      (conversions.to_f / assignments * 100).round(2)
    end

    def calculate_avg_value(conversions)
      values = conversions.where.not(value: nil).pluck(:value)
      return 0.0 if values.empty?
      (values.sum.to_f / values.count).round(2)
    end

    def calculate_significance(control_stats, variant_stats)
      # Simplified z-test for conversion rate comparison
      control_rate = control_stats[:conversion_rate] / 100.0
      variant_rate = variant_stats[:conversion_rate] / 100.0

      control_n = control_stats[:sample_size]
      variant_n = variant_stats[:sample_size]

      return { significant: false, p_value: 1.0 } if control_n < 30 || variant_n < 30

      pooled_rate = (control_stats[:conversions] + variant_stats[:conversions]).to_f / (control_n + variant_n)
      pooled_se = Math.sqrt(pooled_rate * (1 - pooled_rate) * (1.0/control_n + 1.0/variant_n))

      return { significant: false, p_value: 1.0 } if pooled_se.zero?

      z_score = (variant_rate - control_rate) / pooled_se
      p_value = 2 * (1 - normal_cdf(z_score.abs))

      {
        significant: p_value < 0.05,
        p_value: p_value.round(4),
        z_score: z_score.round(4),
        lift: ((variant_rate - control_rate) / control_rate * 100).round(2)
      }
    end

    def normal_cdf(x)
      # Approximation of normal cumulative distribution function
      0.5 * (1 + Math.erf(x / Math.sqrt(2)))
    end

    def determine_winner(significance_results)
      significant_winners = significance_results.select { |_, result| result[:significant] && result[:lift] > 0 }
      return nil if significant_winners.empty?

      # Return variant with highest lift
      significant_winners.max_by { |_, result| result[:lift] }&.first
    end

    def calculate_overall_confidence(significance_results)
      significant_results = significance_results.values.select { |result| result[:significant] }
      return nil if significant_results.empty?

      # Return highest confidence level
      min_p_value = significant_results.min_by { |result| result[:p_value] }[:p_value]
      1 - min_p_value
    end

    def check_sample_size_adequacy(experiment, variant_stats)
      min_sample_size = experiment.minimum_sample_size || 1000

      variant_stats.all? { |_, stats| stats[:sample_size] >= min_sample_size }
    end

    def should_stop_early?(analysis)
      return false unless analysis[:winner]
      return false unless analysis[:confidence]

      # Stop early if confidence > 99% and sample size is adequate
      analysis[:confidence] > 0.99 && analysis[:sample_size_adequate]
    end

    # Helper methods for user targeting
    def extract_platform_from_context(context)
      user_agent = context[:user_agent] || ''
      case user_agent.downcase
      when /iphone|ipad|ios/
        'ios'
      when /android/
        'android'
      else
        'web'
      end
    end

    def get_user_segment(user_id)
      user = User.find_by(id: user_id)
      return 'unknown' unless user

      # Simple segmentation logic
      case
      when user.created_at > 30.days.ago
        'new_user'
      when user.wishlists_count > 10
        'power_user'
      when user.connections_count > 5
        'social_user'
      else
        'regular_user'
      end
    end

    def version_matches?(user_version, target_versions)
      return true if target_versions.blank?

      target_versions.any? do |target|
        case target
        when String
          user_version == target
        when Hash
          operator = target['operator'] || '='
          version = target['version']
          compare_versions(user_version, version, operator)
        end
      end
    end

    def compare_versions(user_version, target_version, operator)
      return false unless user_version && target_version

      user_parts = user_version.split('.').map(&:to_i)
      target_parts = target_version.split('.').map(&:to_i)

      # Pad arrays to same length
      max_length = [user_parts.length, target_parts.length].max
      user_parts.fill(0, user_parts.length...max_length)
      target_parts.fill(0, target_parts.length...max_length)

      comparison = user_parts <=> target_parts

      case operator
      when '=', '=='
        comparison == 0
      when '>'
        comparison > 0
      when '>='
        comparison >= 0
      when '<'
        comparison < 0
      when '<='
        comparison <= 0
      else
        false
      end
    end

    def get_user_country(user_id)
      # This would typically come from IP geolocation or user profile
      'US'
    end

    def is_new_user?(user_id)
      user = User.find_by(id: user_id)
      return false unless user

      user.created_at > 7.days.ago
    end

    def extract_device_info(context)
      {
        platform: context[:platform],
        device_model: context[:device_model],
        os_version: context[:os_version],
        app_version: context[:app_version]
      }.compact
    end

    def filter_by_user_targeting(experiments, user_context)
      experiments.select do |experiment|
        user_qualifies_for_experiment?(experiment, user_context[:user_id], user_context)
      end
    end
  end
end