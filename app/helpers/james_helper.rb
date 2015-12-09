# -*- encoding : utf-8 -*-
module JamesHelper

  # 首页品目标签 品目共三级 
  # 第一级显示在首页上 鼠标悬浮显示二三级 第二级用li_header_tag显示 第三级跳转到channel页面
  def li_header_tag(name, icon = '')
    "<li><div class='category_header'>#{get_name_with_icon(name, icon)}</div></li>".html_safe
  end

  # 首页第三级品目的跳转的li
  def li_link_to_tag(name, id, icon = '')
    "<li><a href='/channel/#{id}' target='_blank'>#{get_name_with_icon(name, icon)}</a></li>".html_safe
  end

  # 首页第三级品目没有产品不用跳转，需加 * 标记
  def li_no_link_tag(name,icon = '')
    "<li><div class='category_grey'>#{get_name_with_icon(name, icon)}</div></li>".html_safe
  end

  # 带日期的li标签 主要用于首页 显示公告
  def li_tag_with_date(title, link_url, date, length = 20, new_cdt=false, new_cont='new', new_color='red')
    
    new_tag = %Q{<span class="text-highlights text-highlights-#{new_color} rounded-2x">#{new_cont}</span>}
    %Q{
      <li>
        <a href='#{link_url}' title='#{title}' target='_blank'>#{text_truncate(title, length)}</a> 
        #{new_tag if new_cdt}
        <span class='hex pull-right'>#{date}</span>
      </li>
    }.html_safe
  end

  # 首页公告li标签
  def article_li_tag(article='', length = 20)
    return '' if article.blank?
    new_cdt = (article.publish_time + article.new_days.days) >= Time.now
    li_tag_with_date(article.title, article_path(article), article.publish_time.to_date, length, new_cdt)
  end  

  # 首页更多标签
  def more_tag(link_url='')
    %Q{
      <span class="badge badge-light pull-right">#{link_to_blank("更多...", link_url, class: "color-light-grey")}</span>
    }.html_safe
  end

  # 占位li
  def li_blank_tag
    "<li>&nbsp;</li>".html_safe
  end

  # 首页 畅销产品展示
  def show_product_div(product)
    img = "/plugins/images/zclfww/product.jpg"
    link_url = product_path(product)
    %Q{
      <div class="col-md-3 col-sm-6">
        <div class="thumbnails thumbnail-style thumbnail-kenburn">
          <div class="thumbnail-img">
            <div class="overflow-hidden">
                <img alt="" src="#{img}" class="img-responsive">
            </div>
            <a href="#{link_url}" class="btn-more hover-effect" target="_blank" title="#{product.name}">详情 +</a>         
          </div>

          <div class="product-description">
            <div class="overflow-h margin-bottom-5">
              <div class="pull-left">
                <h4 class="title-price height-50">
                  #{link_to_blank truncate(product.name, length: 28), link_url, title: product.name}
                </h4>
                <span class="gender text-uppercase">销售范围：全国(厂商协议供货)</span>
                <div class="price_div title-price" id="price_div_#{product.id}">
                  <span class="line-through fl clear font-size-14">市场价：<b class="b_m hide">请登录查看</b></span>
                  <span class="fl clear color-red">入围价：<b class="b_b hide">请登录查看</b></span>
                </div>
              </div>    
            </div>
          </div>

        </div>
      </div>
    }.html_safe
  end

  # 首页入围供应商展示
  def show_dep_div(dep)
    cat = dep.items.map{|e| e.categories.where(ancestry_depth: 2).map(&:name)}.flatten.uniq.join('、')
    %Q{
      <div class="col-md-3 md-margin-bottom-40">
        <div class="easy-block-v1">
          <div id="carouse#{dep.id}-example-generic" class="carousel slide" data-ride="carousel">
            <ol class="carousel-indicators">
              <li class="rounded-x active" data-target="#carouse#{dep.id}-example-generic" data-slide-to="0"></li>
              <li class="rounded-x" data-target="#carouse#{dep.id}-example-generic" data-slide-to="1"></li>
              <li class="rounded-x" data-target="#carouse#{dep.id}-example-generic" data-slide-to="2"></li>
            </ol>
            <div class="carousel-inner">
              <div class="item active">
                <div class="easy-block-v1-badge rgba-default">办公楼外景</div> 
                <img alt="" src="/plugins/images/ad/agents/0_1.jpg">
              </div>
              <div class="item">
                <div class="easy-block-v1-badge rgba-default">车间外景</div> 
                <img alt="" src="/plugins/images/ad/agents/0_2.jpg">
              </div>
              <div class="item">
                <div class="easy-block-v1-badge rgba-default">车间内景</div> 
                <img alt="" src="/plugins/images/ad/agents/0_3.jpg">
              </div>
            </div>
          </div>
          <div class="margin-top-10 font-size-16">#{text_truncate(dep.name, 15)}</div>     
          <ul class="list-unstyled">
            <li><span class="color-green">信用分：</span> #{dep.comment_total}</li>
            <li class="h40"><span class="color-green">入围产品：</span> #{text_truncate(cat, 32)}</li>
          </ul>    
          <a class="btn-u btn-u-sm" href="#">详情 + </a>
        </div>  
      </div>
    }.html_safe
  end

  # 如果是厂家直销显示厂家联系方式
  # 如果是代理商供货 显示总协调人信息
  def get_seller_info(product)
    title = product.cjzx? ? '' : '总协调人'
    man = product.cjzx? ? '联系人' : '总协调人'
    str = %Q{
      <h5><i class="fa fa-chevron-circle-down"></i> 中标单位#{title}联系信息：</h5>
      <div class="row p0_25">
    }
    user = product.cjzx? ? product.department.users.first : product.coordinators.first
    str << %Q{
      <ul class="list-unstyled specifies-list">
        <li><i class="fa fa-caret-right"></i>中标单位名称：<span>#{user.department.real_dep.name}</span></li>
        <li><i class="fa fa-caret-right"></i>#{man}姓名: <span>#{user.try(:name)}</span></li>
        <li><i class="fa fa-caret-right"></i>#{man}电话：<span>#{user.try(:tel)}</span></li>
        <li><i class="fa fa-caret-right"></i>#{man}手机: <span>#{user.try(:mobile)}</span></li>
        <li><i class="fa fa-caret-right"></i>#{man}传真: <span>#{user.try(:fax)}</span></li>
        <li><i class="fa fa-caret-right"></i>#{man}E-Mail: <span>#{user.try(:email)}</span></li>
        <li><i class="fa fa-caret-right"></i>备注: <span>#{user.try(:summary)}</span></li>
      </ul>
      <hr>
    }
    str << "</div>"
    return str.html_safe
  end

end
