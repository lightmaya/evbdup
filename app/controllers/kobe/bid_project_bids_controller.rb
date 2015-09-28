# -*- encoding : utf-8 -*-
class Kobe::BidProjectBidsController < KobeController

	def new
		@bid_project = BidProject.find_by_id(params[:id])
		return render not_found_path unless @bid_project
		@bid = BidProjectBid.new
		@myform = SingleNewForm.new(@bid)
	end
end