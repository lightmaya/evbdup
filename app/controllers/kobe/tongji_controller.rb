# -*- encoding : utf-8 -*-
class Kobe::TongjiController < KobeController
  before_action :set_default_params
  skip_load_and_authorize_resource

  def index
    if params[:search_btn].present?
      common_conditions = get_common_cdt(params[:begin], params[:end])
      # 统计条件加上采购单位
      dep_p = Department.find_by(id: params[:department_id]) if params[:department_id].present?
      buyer = dep_p.present? ? dep_p : current_user.department
      base = Order.find_all_by_buyer_code(buyer.real_dep.id)
      dep_p_group = "concat_ws('/', orders.buyer_code, '')"
      # 统计条件加上供应商单位
      base = base.where(["orders.seller_name like ?", "%#{params[:dep_s_name]}%"]) if params[:dep_s_name].present?

      if params[:category_id].present? && params[:category_id].to_i != 0
        ca = Category.find_by id: params[:category_id]
        ca_group = "concat_ws('/', orders_items.category_code, orders_items.category_id)"
        class_name = base.where(common_conditions).joins(:items).where(["find_in_set(?, replace(#{ca_group}, '/', ',')) >0", params[:category_id]])
        # 按品目统计
        rs = class_name.group(ca_group).select("#{ca_group} as name, #{@sum_total}")
        ca_ha = Hash.new
        ca_ha[ca.name] = rs.select{ |r| r.name == "#{ca.ancestry.blank? ? ca.id : ca.ancestry}/" }.map(&:sum_total).sum
        ca.children.where(status: Category.effective_status).each do |c|
         ca_ha[c.name] = rs.select{ |r| r.name.include?("#{c.ancestry}/#{c.id}/") }.map(&:sum_total).sum
       end
       @categories = ca_ha.sort_by {|key, value| value}.reverse.to_h
        # 按采购单位统计
        rs = class_name.group(dep_p_group).select("#{dep_p_group} as name, #{@sum_total}")
        get_dep_p_rs(rs, buyer)
        # 按采购方式统计
        @yw_types = class_name.group("orders.yw_type").select("orders.yw_type as name, #{@sum_total}").order("sum_total desc")
      else
        class_name = base.where(common_conditions)
        # 按品目统计
        rs = class_name.group("orders.ht_template").select("orders.ht_template as name, sum(orders.total) as sum_total")
        ca_ha = Hash.new
        Dictionary.order_type.values.each do |arr|
          ca_ha[arr[0]] = rs.select{ |r| arr[1].include?(r.name) }.map(&:sum_total).sum
        end
        @categories = ca_ha.sort_by {|key, value| value}.reverse.to_h
        # 采购综合情况
        @total_money = @categories.values.sum
        budget = class_name.sum(:budget_money)
        @save_money = budget - @total_money
        if @total_money == 0
          @lj = @bg = @qc = @save_per = 0
        else
          @save_per = @save_money/@total_money*100
          @lj = @categories["粮机类"]/@total_money*100
          @bg = @categories["办公类"]/@total_money*100
          @qc = @categories["汽车类"]/@total_money*100
        end
        last_year_rs = base.where(get_common_cdt(params[:begin].to_date.last_year.to_s, params[:end].to_date.last_year.to_s)).group("orders.ht_template").select("orders.ht_template as name, sum(orders.total) as sum_total")
        @last_year_ca_ha = Hash.new
        Dictionary.order_type.values.each do |arr|
          @last_year_ca_ha[arr[0]] = last_year_rs.select{ |r| arr[1].include?(r.name) }.map(&:sum_total).sum
        end
        @last_year_total = @last_year_ca_ha.values.sum
        @total_per = @last_year_tota == 0 ? 0 : (@total_money-@last_year_total)/@last_year_total*100
        @lj_per = @last_year_ca_ha["粮机类"] == 0 ? 0 : (@categories["粮机类"] - @last_year_ca_ha["粮机类"])/@last_year_ca_ha["粮机类"]*100
        @bg_per = @last_year_ca_ha["办公类"] == 0 ? 0 : (@categories["办公类"] - @last_year_ca_ha["办公类"])/@last_year_ca_ha["办公类"]*100
        @qc_per = @last_year_ca_ha["汽车类"] == 0 ? 0 : (@categories["汽车类"] - @last_year_ca_ha["汽车类"])/@last_year_ca_ha["汽车类"]*100

        @all_year_total =base.where(get_common_cdt(params[:end].to_date.beginning_of_year.to_s, params[:end])).sum(:total)
        @all_last_year_total =base.where(get_common_cdt(params[:end].to_date.beginning_of_year.last_year.to_s, params[:end].to_date.last_year.to_s)).sum(:total)
        @all_year_per = @all_last_year_total == 0 ? 0 : (@all_year_total-@all_last_year_total)/@all_last_year_total*100
        all_year_budget = base.where(get_common_cdt(params[:end].to_date.beginning_of_year.to_s, params[:end])).sum(:budget_money)
        @all_year_save = all_year_budget - @all_year_total
        @all_year_save_per = @all_year_total == 0 ? 0 : @all_year_save/@all_year_total*100
        # 按采购单位统计
        rs = class_name.group(dep_p_group).select("#{dep_p_group} as name, sum(orders.total) as sum_total")
        get_dep_p_rs(rs, buyer)
        # 按采购方式统计
        @yw_types = class_name.group("orders.yw_type").select("orders.yw_type as name, sum(orders.total) as sum_total").order("sum_total desc")
        # 按供应商销量统计
        common = class_name.select("orders.seller_name as name, sum(orders.total) as sum_total").group("orders.seller_name").order("sum_total desc")
        @lj_rs = common.where(["orders.ht_template in (?)", Dictionary.order_type["lj"].last])
        @bg_rs = common.where(["orders.ht_template in (?)", Dictionary.order_type["bg"].last])
        @qc_rs = common.where(["orders.ht_template in (?)", Dictionary.order_type["qc"].last])
      end
      render layout: (params[:show_type] == 'shape' ? 'tongji' : 'kobe')
    end
  end

  #入围供应商销量统计
  def item_dep_sales
    if params[:search_btn].present?
      @rs = Order.joins(:items).where(get_common_cdt(params[:begin], params[:end])).group("orders.seller_name").select("orders.seller_name, #{@sum_total}").order("sum_total desc")
      if params[:category_id].present?
        ca_ids = params[:category_id].split(",")
        @rs = @rs.where(["orders_items.category_id in (?)", ca_ids])
        item = Item.find_by_category_ids(ca_ids)
        @dep_names = ItemDepartment.where(item_id: item.map(&:id)).map(&:name)
      end
      render layout: (params[:show_type] == 'shape' ? 'tongji' : 'kobe')
    end
  end

  private

    # 默认参数
    def set_default_params
    	params[:begin] ||= Time.now.beginning_of_month.strftime('%Y-%m-%d')
      params[:end] ||=  Time.now.strftime('%Y-%m-%d')
      params[:show_type] ||= 'table'
      dep = current_user.real_department
      params[:department_id] ||= dep.id
      params[:dep_p_name] ||= dep.name
    end

    def get_common_cdt(begin_at, end_at)
      @sum_total = "sum(orders_items.total + orders_items.total*(orders.deliver_fee + orders.other_fee)/(orders.total - orders.deliver_fee - orders.other_fee)) as sum_total"
      common_cdt = []
      common_value = []
      common_cdt << 'orders.status in (?)'
      common_value << Order.effective_status
      common_cdt << 'orders.yw_type <> ?'
      common_value << 'grcg'
      common_cdt << 'orders.created_at between ? and ?'
      common_value << begin_at
      common_value << end_at
      return [common_cdt.join(' and ')] + common_value
    end

    # 根据生成的结果集 组成需要显示的数据
    def get_dep_p_rs(rs, buyer)
      ha = Hash.new
      ha[buyer.name] = rs.select{ |r| r.name == "#{buyer.real_ancestry}/" }.map(&:sum_total).sum
      buyer.children.where(status: Department.effective_status, dep_type: false).each do |dep|
        ha[dep.name] = rs.select{ |r| r.name.include?("#{dep.real_ancestry}/") }.map(&:sum_total).sum
      end
      @departments = ha.sort_by {|key, value| value}.reverse.to_h
    end

end
