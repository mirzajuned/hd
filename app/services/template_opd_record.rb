class TemplateOpdRecord
  attr_reader :patient, :opdrecord, :speciality, :speciality_id, :templatetype, :templateid, :departmentid

  def initialize(patient, opdrecord, speciality, speciality_id, templatetype, templateid, departmentid)
    @patient, @opdrecord, @speciality, @speciality_id, @templatetype, @templateid, @departmentid = patient, opdrecord, speciality, speciality_id, templatetype, templateid, departmentid
  end

  def new_record
    if (speciality_id == 309989009)
      opd_record = OrthopedicsOpdRecord.new(opdrecord, templatetype)

    elsif (speciality_id == 309988001)
      opd_record = OphthalmologyOpdRecord.new(opdrecord, templatetype)

    elsif (speciality_id == 394579002)
      opd_record = CardiologyOpdRecord.new(opdrecord, templatetype)

    elsif (speciality_id == 394537008)
      opd_record = PediatricOpdRecord.new(opdrecord, templatetype)

    elsif (speciality_id == 394802001)
      opd_record = GeneralMedicineOpdRecord.new(opdrecord, templatetype)

    elsif (speciality_id == 394585009)
      opd_record = ObstetricsGynecologyOpdRecord.new(opdrecord, templatetype)

    elsif (speciality_id == 394584008)
      opd_record = GastroenterologyOpdRecord.new(opdrecord, templatetype)

    elsif (speciality_id == 394582007)
      opd_record = DermatologyOpdRecord.new(opdrecord, templatetype)

    elsif (speciality_id == 394583002)
      opd_record = EndocrinologyOpdRecord.new(opdrecord, templatetype)

    elsif (speciality_id == 394589003)
      opd_record = NephrologyOpdRecord.new(opdrecord, templatetype)

    elsif (speciality_id == 394591006)
      opd_record = NeurologyOpdRecord.new(opdrecord, templatetype)

    elsif (speciality_id == 394810000)
      opd_record = RheumatologyOpdRecord.new(opdrecord, templatetype)

    elsif (speciality_id == 418112009)
      opd_record = PulmonaryMedicineOpdRecord.new(opdrecord, templatetype)

    elsif (speciality_id == 465134681)
      opd_record = DentalOpdRecord.new(opdrecord, templatetype)
    end

    opd_record.initialize_nested_objects

    return opd_record
  end

  def open_record
  end
end
