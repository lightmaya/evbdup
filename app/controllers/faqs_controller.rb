class FaqsController < JamesController

	def show
	  @faqs = Faq.where("status= ? and  catalog = ?" , 1 , params[:type])
    @type = params[:type]
	end
	
end