module IpdRecordHelper
  def get_procedure_side_label(eyesideoption)
    eyesideoptionlabel = ""
    Global.ophthalmologyprocedures.eyeside.each do |eyeside_option|
      if eyeside_option['side_id'].to_i == eyesideoption.to_i
        eyesideoptionlabel = eyeside_option['side_abbr']
      end
    end
    eyesideoptionlabel
  end

  def complications_for_procedure_region(procedure_id, excluded_procedure)
    complication_list = []

    unless excluded_procedure
      begin
        complications = YAML.load(File.read("config/global/complications.yml"))
        if complications['default'][procedure_id]
          list = complications['default'][procedure_id]
        else
          procedure_id = CommonProcedure.find_by(code: procedure_id).region.first
          list = complications['default'][procedure_id]
        end
        list.each do |l|
          complication_list << [l['complication_name'], l['code']] # unless excluded_complications.include?(l['complication_name'])
        end
      rescue => e
        @logger.error(" === Error in ipd_record_helper === #{e.inspect}")
      end
    end

    complication_list
  end
end
