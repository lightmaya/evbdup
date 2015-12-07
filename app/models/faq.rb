class Faq < ActiveRecord::Base

	has_many :uploads, class_name: :FaqUpload, foreign_key: :master_id

	include AboutStatus

  default_value_for :status, 0

	before_save do 
    self.status = (self.catalog=='yjjy' ?  58 : 0) if self.new_record?
  end

  
  	# 中文意思 状态值 标签颜色 进度 
	def self.status_array
    # [
    #   ["暂存", "0", "orange", 10], 
    #   ["已发布", "16", "yellow", 40], 
    #   ["未回复", "58", "yellow", 80], 
    #   ["已回复", "75", "dark", 100], 
    #   ["已删除", "404", "dark", 100]
    # ]
    self.get_status_array(["暂存", "已发布", "未回复", "已回复", "已删除"])
		# [
	 #    ["暂存",0,"orange",50],
	 #    ["已发布",1,"u",100],
	 #    ["未回复",2,"blue",80],
	 #    ["已回复",3,"sea",100],
	 #    ["已删除",404,"light",0]
  #   ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   return {
  #     "提交" => { 0 => 1 },
  #     "删除" => { 0 => 404 },
  #     "回复" => { 2 => 3 }
  #   }
  # end

	# 从表的XML加ID是为了修改的时候能找到记录
	def self.xml(catalog='')
    bool = catalog=='yjjy'
		title = bool ?  '建议' : '标题'
		content = bool ? '回复' : '内容'
		if  bool
		str= %Q{
			 	  <node name="发布人" column="ask_user_name" display="readonly" /> 
	        <node name="所在单位" column="ask_dep_name" display="readonly" /> 
	       }
	  end
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	      #{str}
	    	<node name='#{title}' column='title' data_type='textarea' class='required maxlength_800' />  
	    	#{"<node name='#{content}' column='content' data_type='textarea' class='required maxlength_800'/>" if catalog!='yjjy'} 
	    </root>
	  }
	end
end
