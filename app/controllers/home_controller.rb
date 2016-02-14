# -*- encoding : utf-8 -*-
class HomeController < JamesController
  # layout "application" ,:only => :test

  def index
    params[:t] ||= "search_products"
    # 重要通知
    zytz_articles = get_articles('重要通知')
    @zytz = zytz_articles.present? ? zytz_articles.order("id desc").limit(8) : []
    # 招标公告
    zbgg_articles = get_articles('招标公告')
    @zbgg = zbgg_articles.present? ? zbgg_articles.order("id desc").limit(8) : []
    # 招标结果公告
    jggg_articles = get_articles('招标结果公告')
    @jggg = jggg_articles.present? ? jggg_articles.order("id desc").limit(8) : []
    # 网上竞价需求公告
    @wsjj_xq = BidProject.can_bid.order("end_time desc").limit(8)
    # 网上竞价结果公告
    @wsjj_jg = BidProject.where(status: [23, 33]).order("updated_at desc").limit(8)
    # 畅销产品
    @products = Product.show.order("id desc").limit(8)
    # 入围供应商
    # @deps = Department.order("comment_total desc").limit(8)
    @deps = Department.where(old_id: [90853,91337,91178,91125,76588,90829,87920,90849], old_table: "dep_supplier").order("RAND()").limit(8)
    # 协议转让公告
    @xyzr = Transfer.xyzr.order("id desc").limit(8)
    # 无偿划转公告
    @wchz = Transfer.wchz.order("id desc").limit(8)
  end

  # 更多列表
  def more_list
    type_ha = Dictionary.more_tag_type
    if type_ha.has_key? params[:type]
      @title = type_ha[params[:type]]
      # 重要通知 招标公告 招标结果公告
      if params[:type].include? 'article'
        articles = get_articles(type_ha[params[:type]])
        @rs = articles.present? ? articles.order("id desc").page(params[:page]) : []
      end

      # 网上竞价需求公告
      @rs = BidProject.can_bid.order("end_time desc").page(params[:page]) if params[:type] == 'wsjj_xq'
      # 网上竞价结果公告
      @rs = BidProject.where(status: [23, 33]).order("updated_at desc").page(params[:page]) if params[:type] == 'wsjj_jg'

      # 协议转让公告
      @rs = Transfer.xyzr.order("id desc").page(params[:page]) if params[:type] == 'xyzr'
      # 无偿划转公告
      @rs = Transfer.wchz.order("id desc").page(params[:page]) if params[:type] == 'wchz'
    end
  end

  # 入围供应商名单
  def dep_list
    @q = Item.can_search.ransack(params[:q])
    @rs = @q.result
    @rs = @rs.page(params[:page]) if params[:q][:dep_names_cont].present?
    @dep_rs = @rs.first.item_departments.page(params[:page]) if params[:q][:id_eq].present?
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
        if current_user.cgr?
          @products = Product.where("id in (?)", params[:pids].split(","))
          @products.each do |pr|
            @rs << {"id" => pr.id, "bid_price" => ApplicationController.helpers.money(pr.bid_price), "market_price" => ApplicationController.helpers.money(pr.market_price)}
          end
        else
          login = false
        end
      end
    else
      login = false
    end
    render :json => {"success" => login, "rs" => @rs}
  end

  # 全文检索
  def search
    return redirect_to root_path if params[:k].blank?
    case params[:t]
    when "search_products"
      @rs = Product.search(params, {:page_num => 20})
    when "search_gys"
      @rs = Department.search(params, {:page_num => 20})
    when "search_articles"
      @rs = Article.search(params, {:page_num => 20})
    end
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

  def check_ysd
    sn = params[:no].gsub("'", "").strip
    money = params[:m].gsub(",", "").to_f
    @order = Order.find_by("(sn = ? or contract_sn = ? ) and total>= ? and total<= ? and status in (?)",sn,sn,money-0.1,money+0.1,Order.ysd_status )
    if @order.blank?
      render :text => %{<div style="text-align:left;margin:24px;color:#ff0000;">您输入的信息与实际不符，详情请联系服务热线：<br>办公物资：#{Dictionary.service_bg_tel}。<br>粮机物资：#{Dictionary.service_lj_tel}。<br>技术支持：#{Dictionary.technical_support}。</div>}, :layout => false
    else
      if @order.sn == sn
        str = "凭证编号：#{sn}"
        str << "，合计金额：#{@order.total}元，验证网址：http://fwgs.sinograin.com.cn/c/#{sn}?m=#{@order.total}"
        @qr = qrcode(str)
        render partial: '/kobe/orders/print_ysd' , layout: 'print'
      else
        str = "合同编号：#{sn}"
        str << "，合计金额：#{@order.total}元，验证网址：http://fwgs.sinograin.com.cn/c/#{sn}?m=#{@order.total}"
        @qr = qrcode(str)
        render partial: @order.ht , layout: 'print'
      end
    end
  end

  private
    # 查询条件对应
    # [category_id]_[brand]_[sort]_[page]
    def combo_to_conditions(source)
      # 随机排序
      params[:q][:s] = "id asc"
      @combos = params[:combo].split("_")
      # 关键参数
      @all_qs = if source.is_a?(Category)
          rs = Product::QS
          source.get_key_params_nodes.each do |l|
            data = eval l.attr("data")
            next if data.size <= 1
            rs << l.attr("name")
          end
          rs
        else
          Product::QS
        end
      # all_qs = ["brand", "排气量"]
      @all_qs.each_with_index do |q, index|
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
        elsif index < Product::QS.size
          params[:q][q.to_sym] = @combos[index]
        end
      end
      params[:combo] = @combos.join("_")
    end

    def ult(source)
      combo_to_conditions(source)
      clazz = source.products.show

      # 已选条件
      @qs = []
      # 关键参数
      @key_params = []
      keys_conditions = []

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

      # 关键参数
      if source.is_a?(Category)
        source.get_key_params_nodes.each do |l|
          data = eval l.attr("data")
          next if data.size <= 1
          h = {}; data_ary = []
          h["name"] = l.attr("name")

          # 已选参数
          key_index = @combos[@all_qs.index(h["name"])].to_i
          if key_index > 0
            key = data[key_index - 1]
            @qs << {title: "#{h["name"]}：<span>#{key}</span>", id: 0, q: h["name"]}
            keys_conditions << %Q|extractvalue(details, '//node[@name=\"#{h["name"]}\"]/@value') = '#{key}'|
          end

          # extractvalue(details, "//node[@name='排量（L）']/@value") = '2.11'
          # dasd if h["name"] == "座位数（个）"

          data.each_with_index do |d, index|
            data_ary << {title: d, id: index + 1, q: h["name"]} if key_index != index + 1
          end
          h["data"] = data_ary

          @key_params << h
        end
      end

      @q = clazz.where(keys_conditions.join(" and ")).ransack(params[:q])
      @products = @q.result.includes([:category, :uploads]).page(params[:page]).per(20)
      # 推荐产品
      @rec_products = source.products.show.order("id DESC").limit(3)
      # 清理params
      params[:q] = nil; params[:page] = nil
    end

    # 根据公告类别获取公告
    def get_articles(catalog='')
      as = ArticleCatalog.find_by(name: catalog).try(:articles)
      as.where(status: Article.effective_status) if as.present?
    end

end
