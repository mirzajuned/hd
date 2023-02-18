class Attachment
  include Mongoid::Document
  attr_accessor :patientid, :extension
  mount_uploader :attachment, AttachmentUploader

  belongs_to :admission_note
end
