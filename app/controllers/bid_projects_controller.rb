# -*- encoding : utf-8 -*-
class BidProjectsController < JamesController
	def show
		return redirect_to(not_found_path) unless @bid_project = BidProject.find_by_id(params[:id])
	end
end
