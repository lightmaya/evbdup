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
          <div class="caption">
            <h3><a href="#{link_url}" class="hover-effect" target="_blank" title="#{product.name}">#{text_truncate(product.name, 10)}</a></h3>
            <p>
              <strong>市场价：登录查看</strong><br/>
              <strong>中标价：登录查看</strong>
            </p>
          </div>
        </div>
      </div>
    }.html_safe
  end

  # 首页入围供应商展示
  def show_dep_div(dep)
    %Q{
      <div class="col-md-3 md-margin-bottom-40">
        <div class="easy-block-v1">
          <div id="carousel-example-generic" class="carousel slide" data-ride="carousel">
            <ol class="carousel-indicators">
              <li class="rounded-x active" data-target="#carousel-example-generic" data-slide-to="0"></li>
              <li class="rounded-x" data-target="#carousel-example-generic" data-slide-to="1"></li>
              <li class="rounded-x" data-target="#carousel-example-generic" data-slide-to="2"></li>
            </ol>
            <div class="carousel-inner">
              <div class="item active">
                <div class="easy-block-v1-badge rgba-default">TQLZ180×200</div> 
                <img alt="" src="/plugins/images/main/img3.jpg">
              </div>
              <div class="item">
                <div class="easy-block-v1-badge rgba-default">TDSP-650-20米</div> 
                <img alt="" src="/plugins/images/main/img1.jpg">
              </div>
              <div class="item">
                <div class="easy-block-v1-badge rgba-default">TSFQ-50A型</div> 
                <img alt="" src="/plugins/images/main/img7.jpg">
              </div>
            </div>
          </div>
          <div class="margin-top-10 font-size-16">#{text_truncate(dep.name, 15)}</div>     
          <ul class="list-unstyled">
            <li><span class="color-green">信用分：</span> #{dep.comment_total}</li>
            <li><span class="color-green">入围项目：</span> #{dep.items.map{|e| e.categories.where(ancestry_depth: 2).map(&:name)}.flatten.uniq.join('、')}</li>
          </ul>    
          <a class="btn-u btn-u-sm" href="#">更多产品</a>
        </div>  
      </div>
    }.html_safe
  end

end
