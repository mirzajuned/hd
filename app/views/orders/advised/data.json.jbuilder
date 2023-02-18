json.sEcho @s_echo

json.set! "aaData" do
  json.array!(@orders) do |order|

    json.set! "0", '<div class="row" style="margin-left: 10px"><strong>' + (order.try(:type).to_s == "procedures" ? order.try(:procedurename).to_s : order.try(:investigationname)).to_s + ' - ' + order.get_label_for_side(order.try(:type) == 'procedures' ? order.try(:procedureside).to_s : order.try(:investigationside)) + order.get_label_for_radiology_option(order.try(:radiologyoptions).to_s).to_s + '</strong></div><div class="row" style="margin-left: 10px">' + order.try(:advised_by).to_s + '(' + order.try(:advised_datetime).try(:strftime, '%I:%M %p, %d %b %y').to_s + ')</div>'

    # json.set! "1", '<span>' + order.status.to_s + '|' + (order.billing ? 'Billed' : 'Not Billed') + '</span>'
    json.set! "1", '<span>' + order.try(:status).to_s + '</span>'
  end
end
