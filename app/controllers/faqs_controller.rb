# -*- encoding : utf-8 -*-
class FaqsController < JamesController

  def show
    if params[:type] == "yjjy"
      if current_user
        redirect_to new_kobe_faq_path(catalog: "yjjy")
      else
        flash_get("登录后才能发表意见建议，请先登录！")
        redirect_to root_path
      end
    end
    @faqs = Faq.where(status: Faq.effective_status, catalog: params[:type])
  end

end
