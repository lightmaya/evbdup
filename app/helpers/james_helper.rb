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

  # 带日期的li标签 主要用于首页 显示公告 length = 0 表示不用按length截取title
  def li_tag_with_date(title, link_url, date, length = 20, new_cdt=false, new_cont='new', new_color='red')
    new_tag = %Q{<span class="text-highlights text-highlights-#{new_color} rounded-2x">#{new_cont}</span>}
    # “更多..”页面用表格显示
    if length == 0
      return %Q{
        <tr>
          <td><a href='#{link_url}' target='_blank'>#{title}</a>#{new_tag if new_cdt}</td>
          <td>#{date}</td>
        </tr>
      }.html_safe
    else
      return %Q{
        <li>
          <a href='#{link_url}' title='#{title}' target='_blank'>#{text_truncate(title, length)}</a>
          #{new_tag if new_cdt}
          <span class='hex pull-right'>#{date}</span>
        </li>
      }.html_safe
    end
  end

  # 首页公告li标签
  def article_li_tag(article='', length = 20)
    return '' if article.blank?
    new_cdt = (article.publish_time + article.new_days.days) >= Time.now
    li_tag_with_date(article.title, article_path(article), article.publish_time.to_date, length, new_cdt)
  end

  # 网上竞价需求
  def wsjj_xq_li_tag(project, length = 20)
    li_tag_with_date(project.name, bid_project_path(project), project.end_time.to_date, length)
  end

  # 网上竞价结果
  def wsjj_jg_li_tag(project, length = 18)
    unless project.status == 33
      return li_tag_with_date(project.name, bid_project_path(project), project.end_time.to_date, length)
    else
      return li_tag_with_date(project.name, bid_project_path(project), project.end_time.to_date, length, true, '废标')
    end
  end

  # 资产划转 包括无偿划转和协议转让
  def transfer_li_tag(project, length = 20)
    li_tag_with_date(project.name, transfer_path(project), project.submit_time.to_date, length)
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
  def show_product_div(product, hit=nil)
    name = hit && hit.highlight(:name) ? hit.highlight(:name).format { |word| "<span class=\"red\">#{word}</span>" } : product.try(:name)
    img = product.first_img
    link_url = product_path(product)
    %Q{
      <div class="col-md-3 col-sm-6">
        <div class="thumbnails thumbnail-style thumbnail-kenburn">
          <div class="thumbnail-img">
            <a href="#{link_url}" class="hover-effect" target="_blank" title="#{name}">
              <div class="overflow-hidden">
                  <img alt="" src="#{img}" class="img-responsive border-1">
              </div>
            </a>
          </div>

          <div class="product-description">
            <div class="overflow-h margin-bottom-5">
              <div class="pull-left">
                <h4 class="title-price height-50">
                  #{link_to_blank truncate(name, length: 28), link_url, title: name}
                </h4>
                <span class="gender text-uppercase">#{product.item_dep.try(:classify) == 0 ? "&nbsp;" : "供应商级别：#{dep_classify_span(product.item_dep.try(:classify))}" }</span>
                #{check_login_and_show_price(product.id)}
              </div>
            </div>
          </div>

        </div>
      </div>
    }.html_safe
  end

  # 首页入围供应商展示
  def show_dep_div(dep)
    cat = dep.items.usable.where("items.short_name <> '' ").map(&:short_name).compact.uniq.join('、')
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
                <img alt="" src="/plugins/images/ad/agents/thumb/#{dep.old_id}_1.jpg">
              </div>
              <div class="item">
                <div class="easy-block-v1-badge rgba-default">车间外景</div>
                <img alt="" src="/plugins/images/ad/agents/thumb/#{dep.old_id}_2.jpg">
              </div>
              <div class="item">
                <div class="easy-block-v1-badge rgba-default">车间内景</div>
                <img alt="" src="/plugins/images/ad/agents/thumb/#{dep.old_id}_3.jpg">
              </div>
            </div>
          </div>
          <div class="margin-top-10 font-size-16">#{link_to_blank(text_truncate(dep.name, 15),department_path(dep))}</div>
          <ul class="list-unstyled">
            <li class="h40"><span class="color-green">入围产品：</span> #{text_truncate(cat, 32)}</li>
          </ul>
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

  # 根据是否登录显示价格
  def check_login_and_show_price(product_id)
    %Q{
      <div class="product_price_div" id="product_price_div_#{product_id}">
        <p class="color-red hide" id="login_tip_#{product_id}">登录查看价格</p>
        <p id="market_price_#{product_id}"  class="hide"></p>
        <p id="bid_price_#{product_id}" class="hide"></p>
      </div>
    }.html_safe
  end

end
