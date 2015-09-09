# -*- encoding : utf-8 -*-
class ArticleContent < ActiveRecord::Base
	belongs_to :article


	def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='内容' column='content' class='required'/>
      </root>
    }
  end
end
