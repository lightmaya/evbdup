# -*- encoding : utf-8 -*-
module MyFormHelper
  include BaseFunction

  def draw_myform(myform)
    set_top_part(myform) # 设置FORM头部
    set_input_part(myform) #设置主表input
    if myform.options.has_key?(:upload_files) && myform.options[:upload_files] == true
      set_upload_part(myform) # 设置上传附件
    else
      set_bottom_part(myform) # 设置底部按钮和JS校验
    end
    content_tag(:div, raw(myform.html_code).html_safe, :class=>'tag-box tag-box-v6')
  end

	def set_top_part(myform)
    myform.html_code << form_tag(myform.options[:action], method: myform.options[:method], class: 'sky-form no-border', id: myform.options[:form_id]).to_str
    unless myform.options[:title].blank?
      myform.html_code << "<div class='headline'><h2><strong>#{myform.options[:title]}</strong></h2></div>"
    end
	end

	def set_input_part(myform)
    myform.html_code << myform.get_input_part
	end

	def set_upload_part(myform)
		myform.html_code << %Q|
		<input id='#{myform.options[:form_id]}_uploaded_file_ids' name='uploaded_file_ids' type='hidden' />
		</form>|
		# 插入上传组件HTML
		myform.html_code << render(:partial => '/shared/myform/fileupload',:locals => {myform: myform})
	end

	def set_bottom_part(myform)
	  myform.html_code << myform.get_form_button
    myform.html_code << %Q|
    </form>
    <script type="text/javascript">
      jQuery(document).ready(function() {
        var #{myform.options[:form_id]}_rules = {#{myform.rules.join(",")}};
        var #{myform.options[:form_id]}_messages = {#{myform.messages.join(",")}};
        validate_form_rules('##{myform.options[:form_id]}', #{myform.options[:form_id]}_rules, #{myform.options[:form_id]}_messages);
      });
    </script>|
  end

  def get_button_part(myform,self_form=true)
    myform.get_form_button(self_form)
  end
	
end