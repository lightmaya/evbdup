class FaqsController < JamesController

	def show
	  @faqs = Faq.where("status= ? and  catalog = ?" , 1 , params[:type]).order("sort, id desc")
    @type = params[:type]
	end
	
end