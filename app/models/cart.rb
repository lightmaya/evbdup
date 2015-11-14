# -*- encoding : utf-8 -*-
class Cart
  
  attr_accessor :items

  def initialize
    self.items = []
  end

  # 取电商最新价格
  def refresh_prices(area_id = nil)
    self.items.each do |item|
      item.product.update_emall_price(area_id) # if Rails.env.production?
      item.old_price = item.price
      item.price = item.product.price
    end
    refine
  end

  # 购物车中保存product(商品)的id
  def change(product, agent, num, set = false)
    num = num.to_i
    item_id = "#{agent.id}-#{product.id}"
    if current_item = self.items.find { |item| item.id.to_s == item_id }
      set ? current_item.num = num : current_item.cr(num)
      destroy(product) if current_item.num <= 0
    else
      current_item = CartItem.new({:market_price => product.market_price, :ready => true, 
      :bid_price => product.bid_price, :price => product.bid_price, :product_id => product.id, :num => [num, 1].max, 
      :name => product.name, :agent_id => agent.id, :agent_name => agent.name, id: item_id, 
      :big_category_name => product.category.try(:parent).try(:parent).try(:name)})
      self.items = [current_item] + self.items
    end
    self
  end

  def refine
    self.items.delete_if { |item| item.product.blank? || !item.product.show  }
    self
  end

  # 是否准备购买
  def dynamic(product, agent, ready)
    self.items.each do |item|
      item_id = "#{agent.id}-#{product.id}"
      item.ready = ready if item.id == item_id
    end
  end

  def destroy(product_id, agent_id)
    self.items.delete_if { |item| item.id == "#{agent_id}-#{product_id}" }
    self
  end

  def total
    self.items.select{|item| item.ready.present?}.sum(&:total)
  end

  def clean
    self.items = []
  end

end

class CartItem

  attr_accessor :product_id, :num, :price, :name, :sku, :ready, :id,
    :market_price, :old_price, :bid_price, :agent_id, :agent_name, :big_category_name

  def initialize(attributes = {})
    self.product_id = attributes[:product_id]
    attributes[:num] = [attributes[:num].to_i, 1].max
    self.num = attributes[:num].to_i
    self.id = attributes[:id]
    self.bid_price = attributes[:bid_price].to_f
    self.price = attributes[:price].to_f
    self.agent_id = attributes[:agent_id].to_i
    self.agent_name = attributes[:agent_name].to_s
    self.old_price = self.price
    self.name = attributes[:name].to_s
    self.sku = attributes[:sku].to_s
    self.ready = attributes[:ready]
    self.market_price = attributes[:market_price]
    self.big_category_name = attributes[:big_category_name]
  end

  def product
    Product.find_by_id self.product_id
  end

  # 增加或减少购买数量
  def cr(n)
    self.num += n
    self.num = [9999, self.num].min
    self.num = 0 if self.num < 1
  end

  def total
    self.price * self.num
  end

end
