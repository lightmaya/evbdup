# -*- encoding : utf-8 -*-
class Kobe::MainController < KobeController

	skip_load_and_authorize_resource 
	
  def index
    redirect_to kobe_departments_path(id: current_user.department) unless Department.effective_status.include?(current_user.department.status) && User.effective_status.include?(current_user.status)
    if current_user.department.root_id == Department.supplier.try(:id)
      # 最近本单位未完成的订单
      @orders = current_user.department.seller_orders.status_not_in(Order.ysd_status | Order.finish_status).limit(5).order('id desc')
    else
      # 本辖区本年度 采购方式占比
      @type_arr = []
      cdt = "year(created_at) = '#{Time.now.year}' and status in (#{Order.ysd_status.join(', ')})"
      @total = Order.find_all_by_buyer_code(current_user.real_dep_code).where(cdt).sum(:total)
      if @total.present?
        type = Order.find_all_by_buyer_code(current_user.real_dep_code).where(cdt).group('yw_type').select('yw_type, sum(total) as total')
        @type_arr = type.map{ |e| [e.yw_type, e.total.to_f, (e.total*100/@total).to_f] }
      end

      # 粮机类、汽车、办公类采购统计
      category = Order.find_all_by_buyer_code(current_user.real_dep_code).where(cdt).group('ht_template').select('ht_template, sum(total) as total')
      @category_ha = {}
      category.map{ |e|  @category_ha[e.ht_template] = e.total.to_f }

      # 最近本单位未完成的订单
    	@orders = current_user.department.buyer_orders.status_not_in(Order.ysd_status | Order.finish_status).limit(5).order('id desc')
    end
  end

  def to_do
  	
  end
end
