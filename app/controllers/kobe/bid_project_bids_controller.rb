# -*- encoding : utf-8 -*-
class Kobe::BidProjectBidsController < KobeController

	def bid
		@bid_project = BidProject.find_by_id(params[:bid_project_id])
		return redirect_to not_found_path unless @bid_project
		return redirect_to bid_project_path(@bid_project) unless @bid_project.can_bid?
		
		@bid_project_bid = current_user.bid_project_bid(@bid_project)
		
		slave_objs = current_user.bid_item_bids(@bid_project).presence || @bid_project.items
    
    @ms_form = MasterSlaveForm.new(BidProjectBid.xml, BidItemBid.xml, @bid_project_bid, slave_objs,{ upload_files: true,action: kobe_bid_project_bids_path, show_total: true, grid: 4},{title: '产品明细', grid: 4})
	end

end