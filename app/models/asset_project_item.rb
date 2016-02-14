# -*- encoding : utf-8 -*-
class AssetProjectItem < ActiveRecord::Base
  belongs_to :asset_project
  belongs_to :fixed_asset

  # 从表的XML加ID是为了修改的时候能找到记录
  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node column='id' data_type='hidden'/>
        <node column='fixed_asset_id' data_type='hidden'/>
        <node name='车牌号码' column='asset_name' class='requried box_radio' json_url='/kobe/asset_projects/get_fixed_asset_json' partner='fixed_asset_id'/>
        <node name='目前里程表数（公里）' hint='建议每次都填写，至少每月填写一次' class='number'/>
        <node name='加油数量（升）'  hint='油费不为0时必填' class='number'/>
        <node name='油费合计（元）'  class='number amount_total' />
        <node name='油费单价'  class='number' display='readonly' />
        <node name='加油发票数（张）' class='number'/>
        <node name='路桥费合计（元）' class='number amount_total'/>
        <node name='路桥费发票数（张）' class='number'/>
        <node name='停车费合计（元）' class='number amount_total'/>
        <node name='停车发票数（张）' class='number'/>
        <node name='其他费用合计（元）' class='number amount_total'/>
        <node name='其他费用发票数（张）' class='number'/>
        <node name='费用合计（元）' column='total' class='number' display='readonly'/>
      </root>
    }
  end

end
