# -*- encoding : utf-8 -*-
class BargainProduct < ActiveRecord::Base
  belongs_to :bargain
  has_many :bids, class_name: :BargainBidProduct

  # 从表的XML加ID是为了修改的时候能找到记录
  def self.xml(category=nil)
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node column='id' data_type='hidden'/>
        <node name='数量' column='quantity' class='required number'/>
        <node name='计量单位' column='unit' class='required'/>
        #{category.get_key_params_nodes.to_s if category.present?}
      </root>
    }
  end
end
