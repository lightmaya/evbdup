# -*- encoding : utf-8 -*-
class BidProjectBid < ActiveRecord::Base
  belongs_to :bid_project
  has_many :items, class_name: "BidItemBid"

  
end