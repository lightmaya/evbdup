# -*- encoding : utf-8 -*-
class ArticleCatalog < ActiveRecord::Base
	# 树形结构
  has_ancestry :cache_depth => true
  # default_scope -> {order(:ancestry, :sort, :id)}
  has_and_belongs_to_many :articles

  include AboutAncestry
  include AboutStatus

  default_value_for :status, 65

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    # [["正常", "65", "yellow", 100], ["已删除", "404", "dark", 100]]
    self.get_status_array(["正常", "已删除"])
    # [
    #   ["正常", 2, "u", 100],
    #   ["已删除",404,"red",0]
    # ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   {
  #     "删除" => { 2 => 404 }
  #   }
  # end

  # 根据action_name 判断obj有没有操作
  def cando(act='')
    ["delete", "destroy"].include?(act) ? self.can_opt?("删除") : false
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  # def self.status_filter(action='')
  # 	# 列表中不允许出现的
  # 	limited = [404]
  # 	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  # end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='parent_id' data_type='hidden'/>
        <node name='父节点名称' display='disabled'/>
        <node name='名称' column='name' class='required'/>
        <node name='排序号' column='sort' class='digits' hint='只能输入数字,数字越小排序越靠前'/>
      </root>
    }
  end
end
