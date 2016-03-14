# -*- encoding : utf-8 -*-
class BargainBidProduct < ActiveRecord::Base
  belongs_to :bargain_bid
  belongs_to :bargain_product
  belongs_to :product

end
