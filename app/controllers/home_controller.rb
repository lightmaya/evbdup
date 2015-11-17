# -*- encoding : utf-8 -*-
class HomeController < JamesController
  # layout "application" ,:only => :test

  def index
      # trial and error
  end
  
  def ajax_test
      render :text => "这是来自ajax的内容。"
  end

  def json_test
      ztree_nodes_json(Menu)
  end

  def order_success
    
  end

  def form_test
  end

  def check_login
    @rs = []
    if current_user
      login = true
      # 如果有product_id, 返回价格
      if params[:pids].present?
        @products = Product.where("id in (?)", params[:pids].split(","))
        @products.each do |pr| 
          @rs << {"id" => pr.id, "bid_price" => ApplicationController.helpers.money(pr.bid_price), "market_price" => ApplicationController.helpers.money(pr.market_price)}
        end
      end
    else
      login = false
    end
    render :json => {"success" => login, "rs" => @rs}
  end

  def channel
    if @category = Category.usable.find_by_id(params[:combo].to_s.split("_").first)
      ult(@category)
    else
      redirect_to root_path
    end
  end

  def help
  end

  private
    # 查询条件对应
    # [category_id]_[brand]_[sort]_[page]
    def combo_to_conditions
      # 随机排序
      params[:q][:s] = "id asc"
      @combos = params[:combo].split("_")
      Product::QS.each_with_index do |q, index|
        @combos[index] = 0 if @combos[index].blank?
        next if @combos[index].to_i == 0
        if q == "sort"
          if @combos[index].to_i == 1
            params[:q][:s] = "id asc"  
            @id_hash = {title: "上架时间 ▲", id: 2, q: "sort"}
          elsif @combos[index].to_i == 2
            params[:q][:s] = "id desc"  
            @id_hash = {title: "上架时间 ▼", id: 1, q: "sort"}
          elsif @combos[index].to_i == 3
            params[:q][:s] = "market_price asc"  
            @price_hash = {title: "市场价 ▲", id: 4, q: "sort"}
          elsif @combos[index].to_i == 4
            params[:q][:s] = "market_price desc"  
            @price_hash = {title: "市场价 ▼", id: 3, q: "sort"}
          end
        elsif q == "page"
          params[:page] = @combos[index].to_i
          params[:page] = 1 if params[:page] < 1
        else
          params[:q][q.to_sym] = @combos[index]
        end
      end
      params[:combo] = @combos.join("_")
    end

    def ult(source)
      combo_to_conditions
      clazz = source.products.show
      
      # 已选条件
      @qs = []

      # 品牌查询标签
      @all_brands = clazz.group("brand").map(&:brand)
      q_brand_index = @combos[Product::QS.index("brand_eq")].to_i
      if q_brand_index > 0
        q_brand = @all_brands[@combos[q_brand_index].to_i - 1 ]
        params[:q][:brand_eq] = q_brand
        @qs << {title: "品牌：<span>#{q_brand}</span>", id: 0, q: "brand_eq"}
      end
      @brands = []
      @all_brands.each_with_index do |brand, i|
        @brands << {title: brand, id: i+1, q: "brand_eq"} if q_brand_index == 0 || brand != @all_brands[q_brand_index- 1]
      end

      @q = clazz.ransack(params[:q])
      @products = @q.result.includes([:category, :uploads]).page(params[:page]).per(20)
      # 推荐产品
      @rec_products = source.products.show.order("id DESC").limit(3)
      # 清理params
      params[:q] = nil; params[:page] = nil
    end

end
