module GroupBy
  def self.advised_and_performed(records)
    records.group_by { |record| 
      [ record.advised_at&.strftime('%d/%m/%Y'),
        record.advised_by,
        self.performed_at(record),
        record.performed_by
      ]
      }
  end

  private

  def self.performed_at(record)
    date = record.performed_at
    if date.blank?
      inv_record = Investigation::InvestigationDetail.find_by(id: record.investigation_advised_id)
      date = inv_record.performed_at
    end  
    date&.strftime('%d/%m/%Y')
  end
end