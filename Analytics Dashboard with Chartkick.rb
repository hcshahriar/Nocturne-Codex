 class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_dashboard_access

  def index
    @projects_count = current_user.accessible_projects.count
    @active_projects = current_user.accessible_projects.active
    @recent_activity = current_user.recent_activity.limit(10)
    
    @project_stats = project_stats
    @user_activity = user_activity
  end

  private

  def authorize_dashboard_access
    authorize :dashboard, :show?
  end

  def project_stats
    current_user.accessible_projects.group_by_week(:created_at)
      .count
      .transform_keys { |k| k.strftime("%b %d") }
  end

  def user_activity
    current_user.activities.group_by_day(:created_at, range: 30.days.ago..Time.now)
      .count
  end
end


<div class="dark:bg-gray-900 min-h-screen p-6">
  <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
    <div class="bg-gray-800 rounded-lg p-6 shadow-lg">
      <h3 class="text-xl font-semibold text-white mb-4">Projects Overview</h3>
      <%= line_chart @project_stats, 
          colors: ["#6366f1"],
          library: { 
            backgroundColor: "#1f2937",
            textStyle: { color: "#fff" },
            hAxis: { textStyle: { color: "#9ca3af" } },
            vAxis: { textStyle: { color: "#9ca3af" } }
          } %>
    </div>

    <div class="bg-gray-800 rounded-lg p-6 shadow-lg">
      <h3 class="text-xl font-semibold text-white mb-4">Your Activity</h3>
      <%= column_chart @user_activity,
          colors: ["#10b981"],
          library: {
            backgroundColor: "#1f2937",
            textStyle: { color: "#fff" }
          } %>
    </div>

    <div class="bg-gray-800 rounded-lg p-6 shadow-lg">
      <h3 class="text-xl font-semibold text-white mb-4">Quick Stats</h3>
      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <span class="text-gray-300">Total Projects</span>
          <span class="text-white font-bold"><%= @projects_count %></span>
        </div>
        <div class="flex items-center justify-between">
          <span class="text-gray-300">Active Projects</span>
          <span class="text-white font-bold"><%= @active_projects.count %></span>
        </div>
      </div>
    </div>
  </div>
</div>
