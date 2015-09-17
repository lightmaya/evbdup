class Agent < ActiveRecord::Base

  default_scope -> {order("id desc")}
  belongs_to :item
  belongs_to :department

  include AboutStatus

  before_save do 
    self.agent_id = Department.find_by(name: self.name).try(:id)
  end

  # 中文意思 状态值 标签颜色 进度 
  def self.status_array
    [
      ["正常",0,"u",100],
      ["已删除",404,"light",0]
    ]
  end

  # 根据不同操作 改变状态
  def change_status_hash
    {
      "删除" => { 0 => 404 }
    }
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  def self.status_filter(action='')
    # 列表中不允许出现的
    limited = [404]
    arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end

  # 根据action_name 判断obj有没有操作
  def cando(act='',current_u=nil)
    case act
    when "show", "index" then true
    when "update", "edit" then [0,3].include?(self.status) && current_u.try(:id) == self.user_id
    when "delete", "destroy" then self.can_opt?("删除") && current_u.try(:id) == self.user_id
    else false
    end
  end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='代理商名称' column='name' class='required'/>
        <node name='代理地区' class='box_checkbox required' json_url='/kobe/shared/province_area_ztree_json' partner='area_id'/>
        <node column='area_id' data_type='hidden'/>
      </root>
    }
  end

end
