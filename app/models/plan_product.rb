# -*- encoding : utf-8 -*-
class PlanProduct < ActiveRecord::Base
  belongs_to :plan

  # 从表的XML加ID是为了修改的时候能找到记录
  def self.xml(category=nil)
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node column='id' data_type='hidden'/>
        <node name='预算单价（元）' column='price' class='required number' hint='请参照投资计划表填写。'/>
        <node name='数量' column='quantity' class='required number'/>
        <node name='预算总价（元）' column='total' class='required number' display='readonly'/>
        <node name='要求最晚到货日期' column='deliver_at' class='date_select required dateISO'/>
        #{category.get_key_params_nodes.to_s if category.present?}
        <node name='备注' column='summary' data_type='textarea' class='maxlength_800' placeholder='不超过800字'/>
      </root>
    }
  end
end
