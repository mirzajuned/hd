module Invoice::InventoryReportHelper
  def self.patient_info(item)
    age_gender = if item[5].blank? && item[6].blank? 
      ""
    elsif item[5].blank?
      "(#{item[6][0]})"
    elsif item[6].blank?
      "(#{item[5]})"
    else
      "(#{item[5]}/#{item[6][0]})"
    end         
    "#{item[4]}  #{age_gender} <br> #{item[9]}".html_safe
  end

  def self.patient_id_mrn(item)
  	item[8].blank? ? item[7] : "#{item[7]} / <br> #{item[8]}".html_safe
  end
end