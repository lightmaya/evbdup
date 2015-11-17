class Faq < ActiveRecord::Base

	has_many :uploads, class_name: :FaqUpload, foreign_key: :master_id

	  include AboutStatus

	before_save do 
    self.status = self.catalog=='yjjy' ?  1 : 0 
  end

  
  	# 中文意思 状态值 标签颜色 进度 
	def self.status_array
		[
	    ["暂存",0,"orange",50],
	    ["已发布",1,"u",100],
	    ["已删除",404,"light",0]
    ]
  end

  # 根据不同操作 改变状态
  def change_status_hash
    return {
      "提交" => { 0 => 1 },
      "删除" => { 0 => 404 }
    }
  end

	# 从表的XML加ID是为了修改的时候能找到记录
	def self.xml(catalog='',action='')
    bool = ['yjjy','cjwt'].include? catalog
		title = bool ?  '问题' : '标题'
		content = bool ? '答案' : '内容'
		if (action=='edit' && bool) || catalog=='yjjy'
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
