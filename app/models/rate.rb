# -*- encoding : utf-8 -*-
class Rate < ActiveRecord::Base

  include AboutStatus

  default_value_for :status, 0

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    self.get_status_array(["暂存"])
  end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='交货速度（满分4分）' column='jhsd' class='required number' hint='供应商发货速度是否及时，是否按时发货' rules='{max: 4}'/>
        <node name='服务态度（满分4分）' column='fwtd' class='required number' hint='采购过程中供应商的服务态度' rules='{max: 4}'/>
        <node name='产品质量（满分4分）' column='cpzl' class='required number' hint='采购产品与需求产品是否一致' rules='{max: 4}'/>
        <node name='解决问题能力（满分7分）' column='jjwt' class='required number' hint='出现问题时配合解决的速度和解决情况' rules='{max: 7}'/>
        <node name='定期回访（满分7分）' column='dqhf' class='required number' hint='是否定期进行上门或电话回访，是否具有定期的用户巡检制度' rules='{max: 7}'/>
        <node name='现场服务（满分7分）' column='xcfw' class='required number' hint='是否派出技术人员提供现场的技术服务，是否根据需方要求对技术人员进行培训' rules='{max: 7}'/>
        <node name='备品备件（满分7分）' column='bpbj' class='required number' hint='是否免费提供设备质保期内所需的备品备件及易损件，是否免费提供存放部分重要元件备品用于用户维修更换' rules='{max: 7}'/>
        <node column='total' data_type='hidden'/>
        <node name='备注' column='summary' data_type='textarea' placeholder='不超过800字'/>
      </root>
    }
  end

end
