class Kobe::TongjiController < KobeController
  before_action :set_default_params
  before_action :get_common_cdt, only: [:index,:item_dep_sales]
  skip_load_and_authorize_resource

  def index
    if params[:search_btn].present?
      # 按照品目查询
      get_categories
      get_department
      get_yw_type      
      render layout: (params[:show_type] == 'shape' ? 'tongji' : 'kobe') 
    end
  end
 
 #入围供应商销量统计
  def item_dep_sales
    if params[:search_btn].present?
      if params[:item_id].blank? && params[:dep_s_name].blank?
        flash_get('至少选择一种条件')
        render :item_dep_sales
      else
        get_dep_supplier
        render layout: (params[:show_type] == 'shape' ? 'tongji' : 'kobe')
      end
    end
  end

  def get_categories    
  # 按品目统计 如果是叶子节点（没有孩子）只显示总采购金额 如果是父节点（有孩子的）就按当前品目的下一层分类统计
    # 默认没有选品目的话统计第一层 办公类 ，粮机类 
    ca_select = "c.id,c.name,sum(orders_items.total)as total"
    category_sql = %Q{
      select id,name,concat_ws('/',ancestry,id,'') as code from categories 
      where status = 0
    }
    # 求合计
    @category_total = Order.joins(:items).where(@cdt).sum("orders_items.total")
    if params[:category_id].blank?
      category_sql << " and ancestry_depth = 0"
      rs = Order.joins(get_category_joins(category_sql)).select(ca_select).where(@cdt).group('c.code')
      @categories = rs.map{|x| [x.name,x.total.to_f]}
    else
      @ca = Category.find_by(id: params[:category_id])
      if @ca.present?
        if @ca.has_children?
          category_sql << " and find_in_set(#{@ca.id},replace(concat_ws('/',ancestry,id),'/',',')) > 0 and ancestry_depth = #{@ca.ancestry_depth+1} "
          rs = Order.joins(get_category_joins(category_sql)).select(ca_select).where(@cdt).group('c.code')
          @categories = rs.map{|x| [x.name,x.total.to_f]}
          (@ca.children.usable.map(&:name)-rs.map(&:name)).each {|x| @categories << [x,0]}
          category_other = @category_total- rs.map(&:total).sum
          @categories << ['其他',category_other.to_f]  unless category_other == 0
        end
      end
    end
  end

  def get_department    
  # 按品目统计 如果是叶子节点（没有孩子）只显示总采购金额 如果是父节点（有孩子的）就按当前品目的下一层分类统计
    # 默认没有选品目的话统计第一层 中储粮总公司下的各种分公司
    dep_p = Department.purchaser
    # 只显示采购单位的条件
    department_sql = %Q{
      select id,name,concat_ws('/',real_ancestry,'0') as code from departments 
      where  dep_type=0 and find_in_set(#{dep_p.id},replace(real_ancestry,'/',',')) > 0 
    }
    # 求合计
    if params[:category_id].present?
    @department_total = Order.joins(:items).where(@cdt).sum("orders_items.total")
    else
    @department_total = Order.where(@cdt).sum("orders.total")
    end
    if params[:department_id].blank?
      department_sql << " and ancestry_depth <= 2"
      rs = Order.joins(get_department_joins(department_sql)).select(@select).where(@cdt).group('c.code')
      @departments = rs.map{|x| [x.name,x.total.to_f]}
    else
      @dep = Department.find_by(id: params[:department_id])
      if @dep.present?
        if @dep.has_children?
          department_sql << " and find_in_set(#{@dep.id},replace(real_ancestry,'/',',')) > 0 and ancestry_depth <= #{@dep.ancestry_depth+1} "
          rs = Order.joins(get_department_joins(department_sql)).select(@select).where(@cdt).group('c.code')
          @departments = rs.map{|x| [x.name,x.total.to_f]}
          (@dep.children.find_real_dep.map(&:name)-rs.map(&:name)).each {|x| @departments << [x,0]}
        end
      end
    end
    dep_other = @department_total- rs.map(&:total).sum
    @departments << ['其他',dep_other.to_f]  unless dep_other == 0
  end


  def  get_yw_type
    if params[:category_id].present?
    @yw_total = Order.joins(:items).where(@cdt).sum("orders_items.total")
    rs = Order.joins(:items).select("yw_type,sum(orders_items.total) as total").where(@cdt).group("orders.yw_type")
    else
    @yw_total = Order.where(@cdt).sum("orders.total")
    rs = Order.select("yw_type,sum(orders.total) as total").where(@cdt).group("orders.yw_type")
    end
    @yw_types =[]
    yw = Dictionary.yw_type
    yw.each {|k,v| @yw_types << [v,rs.find{|w| w.yw_type== k}.try(:total).to_f]}   
  end

  def get_dep_supplier
    if params[:item_id].present?
      @common_cdt << "items.id = ?"
      @common_value << params[:item_id]
      cdt = [@common_cdt.join(' and ')]+@common_value
      select = "orders.seller_id,orders.seller_name,sum(orders_items.total) as total"
      group = params[:dep_s_name].present? ? 'orders.seller_name' : 'orders.seller_id' 
      rs = Order.select(select).joins(items: :product_item).where(cdt).group(group)
      if params[:dep_s_name].blank?
        @dep_infos = []
        item = Item.find_by(id: params[:item_id])
        item.item_departments.each do |x|
          @dep_infos << [x.name , rs.find{|a| a.seller_id==x.department_id}.try(:total).to_f]
        end
      else
        @dep_infos = rs.map{|x| [x.seller_name,x.total.to_f]}
      end
    else
      rs = Order.select("seller_name,sum(total) as total").where(@cdt).group('seller_name')
      @dep_infos = rs.map{|x| [x.seller_name,x.total.to_f]}
    end
  end


  private

  def set_default_params
  	params[:begin] ||= Time.now.beginning_of_month.strftime('%Y-%m-%d')
    params[:end] ||=  Time.now.strftime('%Y-%m-%d')
    params[:show_type] ||= 'shape' 
  end

  def get_category_joins(sql)
     %Q{
      inner join orders_items on orders.id= orders_items.order_id 
      inner join (#{sql}) c on c.code = left(concat_ws('/',orders_items.category_code,orders_items.category_id,''), length(c.code))
    }
  end

  def get_department_joins(sql)
    %Q{
      #{'inner join orders_items on orders.id = orders_items.order_id' if params[:category_id].present? }
      inner join (#{sql}) c on c.code = left(concat_ws('/',orders.buyer_code,'0'), length(c.code))
    }
  end

  def get_common_cdt
    @select =  params[:category_id].present? ? "c.id,c.name,sum(orders_items.total)as total" : "c.id,c.name,sum(orders.total)as total"
    @common_cdt = []
    @common_value = []
    @common_cdt << 'orders.status in (?)'
    @common_value << Order.effective_status
    @common_cdt << 'orders.created_at between ? and ?'
    @common_value << params[:begin] 
    @common_value << params[:end]
    if params[:category_id].present?
      @common_cdt << "find_in_set(?,replace(concat_ws('/',orders_items.category_code,orders_items.category_id),'/',','))>0"
      @common_value << params[:category_id]
    end
    if params[:department_id].present?
      @common_cdt << "find_in_set(?,replace(orders.buyer_code,'/',','))>0"
      @common_value << params[:department_id]
    end
    if params[:dep_s_name].present?
      @common_cdt << " orders.seller_name like ?"
      @common_value <<  "%#{params[:dep_s_name]}%"
    end
    @cdt = [@common_cdt.join(' and ')] + @common_value
  end

end 