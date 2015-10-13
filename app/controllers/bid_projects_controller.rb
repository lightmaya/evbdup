# -*- encoding : utf-8 -*-
class BidProjectsController < JamesController
	def show
		return redirect_to(not_found_path) unless @bid_project = BidProject.find_by_id(params[:id])

		@obj_contents = info_html(@bid_project, BidProject.xml, {title: "基本信息", grid: 3}) 
    @bid_project.items.each_with_index do |item, index|
      @obj_contents << info_html(item, BidItem.xml, {title: "产品明细 ##{index+1}", grid: 4})
    end


    @before_end = @bid_project.end_time - Time.now
	end
end
