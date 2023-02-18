class GetOrganisation
  def initialize; end

  def self.current_organisation(organisation_id)
    # @current_organisation = $REDIS_L.get("organisation:#{organisation_id}")
    @current_organisation = Redis::Local.new.get("organisation:#{organisation_id}")
    if @current_organisation.nil?
      @current_organisation = Organisation.find_by(id: organisation_id).to_json
      # $REDIS_L.set("organisation:#{organisation_id}", @current_organisation)
      Redis::Local.new.set("organisation:#{organisation_id}", @current_organisation)
      Redis::Local.new.expireat("organisation:#{organisation_id}", ((Date.current + 1).to_time + 4.hours).to_i)

      current_hash = { "organisation:#{organisation_id}" => JSON.parse(@current_organisation) }
      Redis::Master.new.rpush('ehr:current:list', current_hash.to_json)
      current_json = { "organisation:#{organisation_id}" => @current_organisation }
      Redis::Master.new.xadd('ehr:redis_key', current_json, id: '*')

    end
    @current_organisation = JSON.parse(@current_organisation)
  end
end
