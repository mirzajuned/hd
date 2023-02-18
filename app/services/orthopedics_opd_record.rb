class OrthopedicsOpdRecord
  attr_reader :opdrecord, :templatetype

  def initialize(opdrecord, templatetype)
    @opdrecord = opdrecord
    @templatetype = templatetype
  end

  def initialize_nested_objects
    if (templatetype == "express")
      2.times do
        opdrecord.procedure.build
      end
    end
    1.times do
      opdrecord.build_advice
    end
  end

  def self.get_procedures_regions_list_attribute(regions = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}").send(regions.to_sym).map do |procedureregion|
      procedureregion.map.with_index { |procedureregionhash, procedureregionindex| [2, 3].include?(procedureregionindex) ? Hash[procedureregionhash.each_slice(2).to_a] : procedureregionhash[1] }
    end
  end

  def self.get_procedure_side_list_attribute(side = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}#{templatetype}procedures").send(side.to_sym).map do |procedureside|
      procedureside.map.with_index { |proceduresidehash, proceduresideindex| proceduresideindex == 2 ? Hash[proceduresidehash.each_slice(2).to_a] : proceduresidehash[1] }
    end
  end

  def self.get_procedure_status_list_attribute(status = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}#{templatetype}procedures").send(status.to_sym).map do |procedurestatus|
      procedurestatus.map.with_index { |procedurestatushash, procedurestatusindex| procedurestatusindex == 2 ? Hash[procedurestatushash.each_slice(2).to_a] : procedurestatushash[1] }
    end
  end

  def self.get_procedure_approach_list_attribute(approach = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}#{templatetype}procedures").send(approach.to_sym).map do |procedureapproach|
      procedureapproach.map.with_index { |procedureapproachhash, procedureapproachindex| procedureapproachindex == 2 ? Hash[procedureapproachhash.each_slice(2).to_a] : procedureapproachhash[1] }
    end
  end

  def self.get_procedure_type_list_attribute(proceduretype = nil, specalityfoldername, templatetype)
    Global.send("#{specalityfoldername}#{templatetype}procedures").send(proceduretype.to_sym).map do |proceduretype|
      proceduretype.map.with_index { |procedurehash, procedureindex| procedureindex == 2 ? Hash[procedurehash.each_slice(2).to_a] : procedurehash[1] }
    end
  end

  def self.get_procedure_subtype_list_attributes(proceduretype = nil, specalityfoldername, templatetype)
    if proceduretype.nil?
      []
    else
      Global.send("#{specalityfoldername}#{templatetype}procedures").send(proceduretype.to_sym).map do |procedurename|
        # procedurename.values
        procedurename.map.with_index { |procedurenamehash, procedurenameindex| procedurenameindex == 2 ? Hash[procedurenamehash.each_slice(2).to_a] : procedurenamehash[1] }
      end
    end
  end

  def self.get_procedure_qualifier_list_attributes(procedurename = nil, specalityfoldername, templatetype)
    if procedurename.nil?
      []
    else
      Global.send("#{specalityfoldername}#{templatetype}procedures").send(procedurename.to_sym).map do |procedurequalifier|
        # procedurequalifier.values
        procedurequalifier.map.with_index { |procedurequalifierhash, procedurequalifierindex| procedurequalifierindex == 2 ? Hash[procedurequalifierhash.each_slice(2).to_a] : procedurequalifierhash[1] }
      end
    end
  end

  def self.get_procedure_sub_qualifier_list_attributes(proceduresubqualifier = nil, specalityfoldername, templatetype)
    if proceduresubqualifier.nil?
      []
    else
      Global.send("#{specalityfoldername}#{templatetype}procedures").send(proceduresubqualifier.to_sym).map do |proceduresubqualifier|
        proceduresubqualifier.map.with_index { |proceduresubqualifierhash, proceduresubqualifierindex| proceduresubqualifierindex == 2 ? Hash[proceduresubqualifierhash.each_slice(2).to_a] : proceduresubqualifierhash[1] }
      end
    end
  end
end
