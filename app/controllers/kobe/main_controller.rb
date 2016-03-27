# -*- encoding : utf-8 -*-
class Kobe::MainController < KobeController

  skip_load_and_authorize_resource

  def index
    redirect_to kobe_departments_path(id: current_user.department) unless Department.effective_status.include?(current_user.department.status) && User.effective_status.include?(current_user.status)
    # 最近本单位未完成的订单
    if current_user.department.is_dep_supplier?
      @orders = current_user.department.seller_orders.where(status: Order.unfinish_status).limit(5).order('id desc')
    else
      @orders = current_user.department.buyer_orders.where(status: Order.unfinish_status).limit(5).order('id desc')
    end
  end

end
