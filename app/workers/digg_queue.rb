class DiggQueue < BaseWorker
	sidekiq_options :queue => :digg
  def perform(share_id)
    share = Share.find(share_id)
    Rails.logger.info("  Queue: posting to Digg with share id: #{share.item_id}")
  end
end
