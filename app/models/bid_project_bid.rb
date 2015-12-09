# -*- encoding : utf-8 -*-
class BidProjectBid < ActiveRecord::Base
  belongs_to :bid_project
  has_many :items, class_name: "BidItemBid"
  # has_many :uploads, as: :master
  has_many :uploads, class_name: :BidProjectBidUpload, foreign_key: :master_id
  
  belongs_to :user
  belongs_to :department  

  default_value_for :is_bid, 0


  # 附件的类
  def self.upload_model
    BidProjectBidUpload
  end
  
  def self.xml(who = '',options = {})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node column='bid_project_id' data_type='hidden' />
        <node name='项目名称' column='name' class='required' delegate='bid_project'  display="readonly" />
        <node name='采购单位' column='buyer_dep_name' class='required' delegate='bid_project'  display="readonly" />
        <node name='发票抬头' column='invoice_title' class='required' delegate='bid_project'  display="readonly" />
        <node name='供应商单位' column='com_name' class='required' display="readonly" />
        <node name='供应商姓名' column='username' class='required' />
        <node name='供应商电话' column='tel' />
        <node name='供应商手机' column='mobile' class='required' />
        <node name='供应商地址' column='add' class='required' />
        <node name='服务承诺' class='required' data_type='textarea'  />
        <node name='备注' class='required' data_type='textarea' />
      </root>
    }
  end

  # save_xml_form中档保存完slaves以后调用
  def after_slaves_save
    update(total: items.sum("total"))
  end

  def lx
    [self.mobile, self.tel].select{|i| i.present?}.join(" / ")
  end
end
