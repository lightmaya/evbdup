# -*- encoding : utf-8 -*-
class Kobe::BidProjectBidsController < KobeController

	def pre_bid
		@bid_project = BidProject.find_by_id(params[:bid_project_id])
		return redirect_to not_found_path unless @bid_project
		return redirect_to bid_project_path(@bid_project) unless @bid_project.can_bid?
		
		@bid_project_bid = current_user.bid_project_bid(@bid_project)
		
		slave_objs = current_user.bid_item_bids(@bid_project).presence || @bid_project.items.map{|item| BidItemBid.new(bid_item_id: item.id, bid_project_id: @bid_project.id, brand_name: item.brand_name, xh: item.xh) }
    @ms_form = MasterSlaveForm.new(BidProjectBid.xml, BidItemBid.xml, @bid_project_bid, slave_objs, {title: "报价", upload_files: true,action: bid_kobe_bid_project_bids_path, show_total: true, grid: 4},{title: '产品明细', grid: 4, modify: false})
	

	end


	def bid
    @bid_project_bid = create_msform_and_write_logs(BidProjectBid, BidProjectBid.xml, BidItemBid, BidItemBid.xml, {:action => "报价", :master_title => "基本信息", :slave_title => "产品信息"})
		redirect_to action: :index
	end


	def index
    @q = BidProject.can_bid.ransack(params[:q]) 
    @bid_projects = @q.result.page params[:page]
	end

end