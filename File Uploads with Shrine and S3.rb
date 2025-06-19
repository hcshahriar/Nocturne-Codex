require "shrine"
require "shrine/storage/s3"

s3_options = {
  access_key_id:     ENV.fetch('AWS_ACCESS_KEY_ID'),
  secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
  region:            ENV.fetch('AWS_REGION'),
  bucket:            ENV.fetch('AWS_BUCKET')
}

Shrine.storages = {
  cache: Shrine::Storage::S3.new(prefix: "cache", **s3_options),
  store: Shrine::Storage::S3.new(prefix: "store", **s3_options)
}

Shrine.plugin :activerecord
Shrine.plugin :cached_attachment_data
Shrine.plugin :restore_cached_data
Shrine.plugin :validation_helpers
Shrine.plugin :determine_mime_type
Shrine.plugin :derivatives
Shrine.plugin :backgrounding

Shrine::Attacher.promote_block do
  FileUploadPromoteJob.perform_later(
    self.class.name,
    record.class.name,
    record.id,
    name,
    file_data
  )
end


class FileUploader < Shrine
  plugin :derivatives
  plugin :add_metadata
  plugin :remote_url, max_size: 20*1024*1024

  Attacher.validate do
    validate_max_size 100.megabytes, message: "is too large (max is 100 MB)"
    validate_mime_type_inclusion %w[
      image/jpeg image/png image/gif
      application/pdf
      text/plain
      application/zip
    ]
  end

  metadata_method :dimensions, :analyze

  def analyze(io, context)
    return unless image?(io)

    dimensions = ImageProcessing::MiniMagick
      .source(io)
      .loader(page: 0)
      .resize_to_limit!(1600, 1600)

    { width: dimensions.width, height: dimensions.height }
  end
end
class ProjectFile < ApplicationRecord
  include FileUploader::Attachment(:file)

  belongs_to :project
  belongs_to :user

  validates :file, presence: true
end
