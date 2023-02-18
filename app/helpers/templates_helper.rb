module TemplatesHelper
  # def self.get_speciality_name(specialitynamefoldername)
  #   Global.ehrcommon.specialities.find { |speciality_hash| speciality_hash["specalityname"] == specialitynamefoldername }["specalityid"]
  # end
  # commenting this method, found duplicate name on line #13

  def self.get_speciality_folder_name(specalityid)
    specialities = Global.ehrcommon.specialities.find { |speciality_hash| speciality_hash["specalityid"] == specalityid.to_i }
    specialities["templatesfoldername"] if specialities.present?
    # Global.ehrcommon.specialities.find { |speciality_hash| speciality_hash["specalityid"] == specalityid.to_i }["templatesfoldername"] # eachspecalityhash.values.first, you can the same code aseachspecalityhash['specalityid']. specalityid must be first value in the hash of Global.ehrcommon.specialities
  end

  def self.get_speciality_name(specalityid)
    if specalityid.present?
      Global.ehrcommon.specialities.find { |speciality_hash| speciality_hash["specalityid"] == specalityid.to_i }["specalityname"]
    end
    # eachspecalityhash.values.first, you can the same code aseachspecalityhash['specalityid']. specalityid must be first value in the hash of Global.ehrcommon.specialities
  end

  def self.get_template_id_for_speciality_and_templatename(specialityname, templatename)
    Global.send("#{specialityname}").send("#{templatename}template").templateid
  end

  def self.get_template_display_name_for_speciality_and_templatename(specialityname, templatename)
    Global.send("#{specialityname}").send("#{templatename}template").displayname
  end

  def self.get_template_id_for_patienthistory_template(templatename)
    Global.send("ehrcommon").send("#{templatename}template").templateid
  end

  def self.get_ipd_templateid_displayname(templatename)
    template_object = []
    template_object[0] = Global.send("ipd").send("#{templatename}").templateid
    template_object[1] = Global.send("ipd").send("#{templatename}").displayname
    template_object
  end

  def self.defined_rules_files(specialityname, templatename)
    Global.send("#{specialityname}").send("#{templatename}template").rules
  end

  def self.cloneable_rules_files(specialityname, templatename)
    Global.send("#{specialityname}").send("#{templatename}template").cloneable_rules
  end
end
