require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password).on(:create) }
  end

  describe 'roles' do
    it 'assigns default user role' do
      expect(user).to have_role(:user)
    end

    it 'can be promoted to admin' do
      user.add_role(:admin)
      expect(user).to have_role(:admin)
    end
  end

  describe '#admin?' do
    it 'returns true for admin users' do
      expect(admin.admin?).to be true
    end

    it 'returns false for regular users' do
      expect(user.admin?).to be false
    end
  end
end


require 'rails_helper'

RSpec.describe 'Dashboard', type: :system do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  before do
    driven_by(:selenium_chrome_headless)
  end

  context 'as regular user' do
    before do
      login_as(user)
      visit dashboard_path
    end

    it 'displays the dashboard page' do
      expect(page).to have_content('Dashboard')
    end

    it 'shows project stats' do
      expect(page).to have_css('#project-stats-chart')
    end
  end

  context 'as admin user' do
    before do
      login_as(admin)
      visit dashboard_path
    end

    it 'shows admin-specific metrics' do
      expect(page).to have_content('Admin Dashboard')
    end
  end
end

require 'rails_helper'

RSpec.describe ProjectExportJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, owner: user) }

  before do
    allow(ProjectExporter).to receive_message_chain(:new, :export_to_zip).and_return(Tempfile.new)
  end

  it 'queues the job' do
    expect {
      ProjectExportJob.perform_later(user.id, project.id)
    }.to have_enqueued_job.on_queue('exports')
  end

  it 'exports the project' do
    expect(ProjectExporter).to receive(:new).with(project)
    perform_enqueued_jobs do
      ProjectExportJob.perform_later(user.id, project.id)
    end
  end

  it 'sends completion email' do
    expect {
      perform_enqueued_jobs do
        ProjectExportJob.perform_later(user.id, project.id)
      end
    }.to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
