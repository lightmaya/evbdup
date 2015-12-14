class FixedAsset < ActiveRecord::Base

  belongs_to :department

  include AboutStatus

  default_value_for :status, 65

  after_create do 
    create_no("QC", "sn")
  end

  #剩余资产价值
  def left_value
    if self.gouzhi_riqi.nil? || self.gouzhi_jiage.nil? || self.zhejiulv.nil?
      return nil
    else
      year = Time.new.strftime("%Y").to_i - self.gouzhi_riqi.strftime("%Y").to_i
      month = Time.new.strftime("%m").to_i - self.gouzhi_riqi.strftime("%m").to_i
      mons = month + year * 12
      mons += 1 if Time.new.strftime("%d").to_i > self.gouzhi_riqi.strftime("%d").to_i  # 不足一月按一个月算
      return self.gouzhi_jiage * (1 - mons * self.zhejiulv / (12 * 100))
    end
  end

  # 中文意思 状态值 标签颜色 进度 
  def self.status_array
    # [["正常", "65", "yellow", 100], ["已删除", "404", "dark", 100]]
    self.get_status_array(["正常", "已删除"])
    # [
    #   ["正常",0,"u",100],
    #   ["已删除",404,"light",0]
    # ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   return {
  #     "删除" => { 0 => 404 }
  #   }
  # end


  # 根据action_name 判断obj有没有操作
  def cando(act='',current_u=nil)
    case act
    when "show" 
      true
    when "update", "edit" 
      self.class.edit_status.include?(self.status) && current_u.try(:id) == self.user_id
    when "delete", "destroy" 
      self.can_opt?("删除") && current_u.try(:id) == self.user_id
    else false
    end
  end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='车牌号码' column='name' hint='车牌号码务必要填写完整、规范，例如：京AXXXXX' class='required' />
        <node name='车架号' class='required'/>
        <node name='发动机号' class='required'/>
        <node name='品牌' class='required' />
        <node name='型号' class='required' />
        <node name='排量' class='required' data_type='select' data="['小于或等于1.4','1.6','1.8','2.0','2.3','2.4','2.5','3.0','4.0','4.2','4.6','1.4T','1.8T','2.0T','2.4T','3.0T','大于3.0']"/>
        <node name='车身颜色' data_type='select' data="['黑色','白色']"/>
        <node name='座位数(个)' class='required' data_type='select' data="['4','5','6','7','8','9']"  />
        <node name='单位名称' column='dep_name' class='required'/>
        <node name='负责人' column='fuzeren' />
        <node name='购置金额(不含税/元)' column='gouzhi_jiage' class='required number'/>
        <node name='购置税(元)' column='gouzhi_shui' hint='如果没有购置税请填0。' class='required number'/>
        <node name='购置日期' column='gouzhi_riqi' class='date_select required dateISO'/>
        <node name='资金来源' />
        <node name='用途' />
        <node name='使用方式' />
        <node name='年折旧率(%)' column='zhejiulv' hint='仅填写百分比后面的数字，例如&lt;br&gt;年折旧率为：8%，则填写：8。' class='required number'/>
        <node name='启用日期' column='qiyong_riqi' hint='如果此物品有日常维护费用支&lt;br&gt;出，则从启用日期开始算起。' class='date_select required dateISO'/>
        <node name='报废日期' column='baofei_riqi' hint='已报废的请填写报废时间。' class='date_select dateISO'/>
        <node name='转移日期' column='zhuanyi_riqi' class='date_select dateISO'/>
        <node name='转移单位' column='zhuanyi_danwei'/>
        <node name='状态' column='asset_status' class='required' data_type='select' data='#{Dictionary.asset_status}'/> 
      </root>
    }
  end

end





