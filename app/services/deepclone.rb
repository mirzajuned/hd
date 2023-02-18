class Deepclone
  def initialize
  end

  def self.clone_all_attributes(classname, record_id, options = {}, skip_otions = {})
    # puts classname
    record = classname.find_by(id: record_id)
    clone_record = classname.new
    # clone_record = record.clone
    associations = [:embeds_many, :embeds_one]
    record.attributes.each do |key, value|
      embedded_atrributes = classname.reflect_on_all_associations(associations[0]).map { |i| i.name.to_s } + classname.reflect_on_all_associations(associations[1]).map { |i| i.name.to_s }
      next if ['_id', 'created_at', 'updated_at'].include? key
      next if embedded_atrributes.include? key

      clone_record[key] = value
    end
    clone_record['created_at'] = Time.current
    clone_record['updated_at'] = Time.current
    clone_record['is_copied'] = true
    options.each do |key, value|
      clone_record[key] = value
    end
    clone_record['is_copied'] = true
    associations.each do |macro|
      puts "___________________________________", macro, "--------------"
      if classname.reflect_on_all_associations(macro).size > 0
        # assosiates = classname.reflect_on_all_associations(macro).map{|assosiate| assosiate.name}
        classname.reflect_on_all_associations(macro).each do |associate|
          puts associate.name
          next if skip_otions.values.include? associate.name

          record.send(associate.name).each do |associate_attr|
            clone_record_embedded_obj = clone_record.send(associate.name).new
            associate_attr.attributes.each do |key, value|
              next if ['_id', 'created_at', 'updated_at'].include? key

              clone_record_embedded_obj[key] = value
            end
            clone_record_embedded_obj['created_at'] = Time.current
            clone_record_embedded_obj['is_copied'] = true
          end
        end
      end
    end
    clone_record
  end
end
