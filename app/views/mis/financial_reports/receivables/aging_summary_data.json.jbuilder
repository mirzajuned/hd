# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_payer_payments_count
json.iTotalDisplayRecords @total_payer_payments_count
json.set! "aaData" do
  currency_symbol = @mis_params[:currency_symbol].to_s

  json.array!(@payer_payments) do |payer_payment|
    grouped_by_days = payer_payment[:payer_payments].group_by { |v| (Date.current - v[:date].to_date).to_i }

    # Contact Name
    contact_name = payer_payment[:_id][:contact_name]

    # Current (Today)
    current = grouped_by_days.map { |k, v| v if [*0].include?(k) }.delete_if(&:nil?).flatten.pluck(:pending_total).sum.to_f.round(2)

    # 1-15 Days
    o_f_days = grouped_by_days.map { |k, v| v if [*1..15].include?(k) }.delete_if(&:nil?).flatten.pluck(:pending_total).sum.to_f.round(2)

    # 16-30 Days
    s_t_days = grouped_by_days.map { |k, v| v if [*16..30].include?(k) }.delete_if(&:nil?).flatten.pluck(:pending_total).sum.to_f.round(2)

    # 31-45 Days
    t_f_days = grouped_by_days.map { |k, v| v if [*31..45].include?(k) }.delete_if(&:nil?).flatten.pluck(:pending_total).sum.to_f.round(2)

    # 46-60 Days
    f_s_days = grouped_by_days.map { |k, v| v if [*46..60].include?(k) }.delete_if(&:nil?).flatten.pluck(:pending_total).sum.to_f.round(2)

    # >60 Days
    a_s_days = grouped_by_days.map { |k, v| v if k > 60 }.delete_if(&:nil?).flatten.pluck(:pending_total).sum.to_f.round(2)

    # Total
    total = current + o_f_days + s_t_days + t_f_days + f_s_days + a_s_days

    # Table Data
    json.set! "0", contact_name
    json.set! "1", currency_symbol + current.to_s
    json.set! "2", currency_symbol + o_f_days.to_s
    json.set! "3", currency_symbol + s_t_days.to_s
    json.set! "4", currency_symbol + t_f_days.to_s
    json.set! "5", currency_symbol + f_s_days.to_s
    json.set! "6", currency_symbol + a_s_days.to_s
    json.set! "7", currency_symbol + total.to_s
  end
end
