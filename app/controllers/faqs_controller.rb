class FaqsController < JamesController

	def show
	  @faqs = Faq.where(status: Faq.effective_status, catalog: params[:type]).order("sort, id desc")
    @type = params[:type]
	end
	
end