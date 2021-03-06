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
  def change(product, seller, num, set = false)
    num = num.to_f
    cart_item_id = "#{product.id}-#{seller.class}-#{seller.id}"
    # 同一供应商id
    sid = "#{seller.class}-#{seller.id}"
    if current_item = self.items.find { |item| item.id.to_s == cart_item_id }
      set ? current_item.num = num : current_item.cr(num)
      destroy(cart_item_id) if current_item.num <= 0
    else
      current_item = CartItem.new({:market_price => product.market_price, :ready => true, :summary => product.summary,
      :bid_price => product.bid_price, :price => product.bid_price, :product_id => product.id, :num => num, # [num, 1].max,
      :name => product.name, :seller_id => seller.id, id: cart_item_id, sid: sid,
      :seller_name => seller.name, ht: product.category.ht_template,
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
  def dynamic(cart_item_id, ready)
    self.items.each do |item|
      item.ready = ready if item.id == cart_item_id
    end
  end

  def destroy(cart_item_id)
    self.items.delete_if { |item| item.id == "#{cart_item_id}" }
    self
  end

  def total
    self.items.select{|item| item.ready.present?}.sum(&:total)
  end

  def clean
    self.items = []
  end

  # 已勾选的商品
  def ready_items
    self.items.select{|item| item.ready }
  end

  # 同一供应商
  def same_seller?
    ready_items.map(&:sid).uniq.size == 1
  end

  # 同一ht
  def same_ht?
    ready_items.map(&:ht).uniq.size == 1
  end

end

class CartItem

  attr_accessor :product_id, :num, :price, :name, :sku, :ready, :id, :ht, :sid,
    :market_price, :old_price, :bid_price, :seller_id, :seller_name, :big_category_name, :summary

  def initialize(attributes = {})
    self.product_id = attributes[:product_id]
    # attributes[:num] = [attributes[:num].to_i, 1].max
    self.num = attributes[:num].to_f
    self.id = attributes[:id]
    self.sid = attributes[:sid]
    self.ht = attributes[:ht]
    self.bid_price = attributes[:bid_price].to_f
    self.price = attributes[:price].to_f
    self.seller_id = attributes[:seller_id].to_i
    self.seller_name = attributes[:seller_name].to_s
    self.old_price = self.price
    self.name = attributes[:name].to_s
    self.sku = attributes[:sku].to_s
    self.ready = attributes[:ready]
    self.market_price = attributes[:market_price]
    self.big_category_name = attributes[:big_category_name]
    self.summary = attributes[:summary]
  end

  def product
    Product.find_by_id self.product_id
  end

  # 增加或减少购买数量
  def cr(n)
    self.num += n
    self.num = [999999999, self.num].min
    self.num = 0 if self.num < 1
  end

  def total
    self.price * self.num
  end

end
