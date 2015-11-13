

## 字段及表单

* 在model中定义xml方法，每个dom的类型，样式等（范例：article.rb）
```ruby
def self.xml
  %Q{
    <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='公告标题' column='title' class='required'/>
      </root>
    }
end

# name: label名称
# column: 对应字段
# class: 样式及效验. [required]必须填写
# data='#{Dictionary.top_type}':application.yml中定义的参数 data_type='select'： 下拉选择
# data_type='richtext' style='width:100%;height:300px;': 富文本框um和宽度高度
# data_type: 'hidden', 'richtext', 'textarea', 'select', 'radio'
# display: 'skip'
# class='tree_checkbox'： 多选树形结构 json_url='/kobe/shared/ztree_json' ，json_params='{"json_class":"ArticleCatalog"}'：具体树的方法和类 partner='catalog_ids'：存入的input的id
```

* action new方法中，使用SingleForm生成表单对象（范例：kobe/articles_controller.rb）
```ruby
@myform = SingleForm.new(Article.xml, @article, 
{ form_id: "article_form", action: kobe_articles_path,
title: '<i class="fa fa-pencil-square-o"></i> 新增公告', grid: 2  
})
# grid表示每行显示的字段标签td数量
```

* new.html.erb 生成表单
```ruby
<%= draw_myform(@myform) %>
```

* create方法中, 保存并记录日志
```ruby
article = create_and_write_logs(Article, Article.xml)
```

* update方法中
```ruby
 update_and_write_logs(@article, Article.xml)
```

* 删除，默认都是404软删除
```ruby
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_article_form', action: kobe_article_path(@article), method: 'delete' }
  end

  def destroy
    @article.change_status_and_write_logs("已删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_articles_path
  end
```

* index.html.erb中
```ruby
 # 状态的查询和显示
 <th class="status_bar"><%= status_filter(Article) %></th>
 <td><%= article.status_bar %></td>
 # 日期的查询和显示
 <th class="date"><%= date_filter %></th>
 <td><%= show_date(article.created_at) %></td>
 # 操作在BtnArrayHelper.rb中定义
 <td><%= btn_group(articles_btn(article)) %></td>
```

## status字段及审核相关，范例：article.rb
```ruby
# 有status字段的需要加载AboutStatus
  include AboutStatus
  # 列表中的状态筛选, current_status当前状态不可以点击
  def self.status_filter(action='')
  	# 列表中不允许出现的， 404表示已删除， 系统中默认都是软删除
  	# limited = [404] 
    limited = []
    # a[1] : 0
    # 返回 [["暂存", 0], ["等待审核", 2]]，形成页面筛选条件
  	arr = self.status_array.delete_if{|a| limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end

  # status各状态的中文意思 状态值 标签颜色 进度 
	def self.status_array
		[
	    ["暂存", 0, "orange", 50],
      ["等待审核", 1, "orange", 90],
	    ["已发布", 2, "u", 100],
      ["审核拒绝",3,"red",0],
	    ["已删除", 404, "red", 0]
    ]
  end

  # 根据不同操作 改变状态
  # "提交审核"与action中obj.change_status_and_write_logs一致
  def change_status_hash
    {
      "提交审核" => { 0 => 1 },
      "删除" => { 0 => 404 },
      "通过" => { 1 => 2 },
      "不通过" => { 1 => 3 }
    }
  end
```