class OrderJobs::PerformedJob < ActiveJob::Base
  queue_as :urgent

  def perform(ids, performed)
    if ids.present? && ids.compact.present?
      params = {is_performed: performed, status: performed ? 'Performed' : 'Advised'}
      params[:active] = !performed
      Order::Advised.where(id: { :$in => ids.compact }).update_all(params)
      Order::Advised.where(id: { :$in => ids.compact }).each do |order_advised|
        Orders::Trails::CreateService.call(performed ? 'Performed' : 'Advised', order_advised)
      end
    end
  end
end
  