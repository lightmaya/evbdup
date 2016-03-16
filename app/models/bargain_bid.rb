# -*- encoding : utf-8 -*-
class BargainBid < ActiveRecord::Base
  belongs_to :bargain
  has_many :products, class_name: "BargainBidProduct"

  belongs_to :department

  default_value_for :is_bid, 0

  after_save do
    # 最后一个供应商报完价 进入下一个流程
    if self.bargain.can_bid? && !self.bargain.bids.map(&:has_bid?).include?(false)
      obj = self.bargain
      cs = obj.get_current_step
      if cs.is_a?(Hash)
        ns = obj.get_next_step
        rule_step = ns.is_a?(Hash) ? ns["name"] : ns
        st = obj.get_change_status("通过")
        obj.update(status: st, rule_step: rule_step)
        # 插入待办事项
        obj.reload.create_task_queue
      end
    end
  end

  # 报价单位在某项目的级别
  def classify
     ItemDepartment.find_by(item_id: self.bargain.item_id, department_id: self.department_id).try(:classify)
  end

  # 是否已经报价
  def has_bid?
    self.total > 0 && self.products.present?
  end

  # 更新中标情况
  def update_bid_success
    self.bargain.bids.update_all(is_bid: false)
    self.update(is_bid: true)
  end


  def self.xml(show_type='all')
    str = %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
    }
    if ["all", "info"].include? show_type
      str << %Q{
          <node name='供应商单位' column='name' class='required' display="readonly" />
          <node name='供应商姓名' column='dep_man' class='required' />
          <node name='供应商电话' column='dep_tel' />
          <node name='供应商手机' column='dep_mobile' class='required' />
          <node name='供应商地址' column='dep_addr' class='required' />
          <node name='备注' data_type='textarea' />
      }
    end
    if ["all", "fee"].include? show_type
      str << %Q{
        <node name='运费（元）' column='deliver_fee' class='number'/>
        <node name='其他费用（元）' column='other_fee' class='number' hint='如填写其他费用，请填写其他费用说明'/>
        <node name='其他费用说明' column='other_fee_desc'/>
      }
    end
    str << %Q{
        <node column='total' data_type='hidden'/>
      </root>
    }
    return str
  end

end
