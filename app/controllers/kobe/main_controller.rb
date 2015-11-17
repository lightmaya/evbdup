# -*- encoding : utf-8 -*-
class Kobe::MainController < KobeController

	skip_load_and_authorize_resource 
	
  def index
    # 本辖区本年度 采购方式占比
    cdt = "year(created_at) = '#{Time.now.year}' and status in (3)"
    total = Order.find_all_by_buyer_code(current_user.department.real_ancestry).where(cdt).sum(:total)
    total = 0 if total.blank?
    yw_type = Order.find_all_by_buyer_code(current_user.department.real_ancestry).where(cdt).group('yw_type').select('yw_type, sum(total) as total')
    if total == 0 
      @xygh = @ddcg = @wsjj = 0
    else
      @xygh = yw_type.find{ |e| e.yw_type == 'xygh'}.present? ? (yw_type.find{ |e| e.yw_type == 'xygh'}.total*100/total).to_f : 0
      @ddcg = yw_type.find{ |e| e.yw_type == 'ddcg'}.present? ? (yw_type.find{ |e| e.yw_type == 'ddcg'}.total*100/total).to_f : 0
      @wsjj = yw_type.find{ |e| e.yw_type == 'wsjj'}.present? ? (yw_type.find{ |e| e.yw_type == 'wsjj'}.total*100/total).to_f : 0
    end

    # 粮机类、办公类采购统计

    # 最近本单位未完成的订单
  	@orders = current_user.department.buyer_orders.status_not_in([3]).limit(5)
  end

  def to_do
  	
  end
end
