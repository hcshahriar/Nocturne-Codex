# app/jobs/project_export_job.rb
class ProjectExportJob < ApplicationJob
  queue_as :exports
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
  discard_on ActiveJob::DeserializationError

  before_perform :track_start
  after_perform :track_completion

  def perform(user_id, project_id)
    user = User.find(user_id)
    project = Project.find(project_id)

    authorize_export!(user, project)

    exporter = ProjectExporter.new(project)
    file = exporter.export_to_zip

    ProjectExportMailer.with(user: user, project: project)
                      .export_completed(file)
                      .deliver_later
  end

  private

  def authorize_export!(user, project)
    ability = Ability.new(user)
    raise "Unauthorized export" unless ability.can?(:export, project)
  end

  def track_start
    Rails.logger.info "[#{self.class}] Starting export for #{arguments[0]}"
  end

  def track_completion
    Rails.logger.info "[#{self.class}] Completed export for #{arguments[0]}"
  end
end

# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
  config.error_handlers << Proc.new do |ex, ctx_hash|
    Sentry.capture_exception(ex, extra: ctx_hash)
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
end
