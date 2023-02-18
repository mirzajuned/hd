json.set! 'user' do
  json.fullname @user.fullname
end

json.set! 'user_statuses' do
  json.array!(@user_statuses) do |user_status|
    json.start_time user_status.start_time
    json.end_time user_status.end_time
    json.state user_status.state
    json.quota user_status.quota
    json.modified_by user_status.modified_by
    json.span user_status.span.to_i
    json.deleted user_status.deleted
  end
end
