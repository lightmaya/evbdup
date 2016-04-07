# -*- encoding : utf-8 -*-
module MyFormHelper
  include BaseFunction

  def draw_myform(myform)
    set_top_part(myform) # 设置FORM头部
    set_input_part(myform) #设置主表input
    if myform.options.has_key?(:show_total)
      set_total_part(myform) if myform.options[:show_total] == true # 设置主从表金额
      set_total_by_array(myform) if myform.options[:show_total].is_a?(Array) # 根据数组计算单表的金额
    end
    if myform.options.has_key?(:upload_files) && myform.options[:upload_files] == true
      set_upload_part(myform) # 设置上传附件
    else
      set_bottom_part(myform) # 设置底部按钮和JS校验
    end
    content_tag(:div, raw(myform.html_code).html_safe, :class=>'tag-box tag-box-v6')
  end

  def set_top_part(myform)
    # kobe_articles_path
    obj = myform.obj
    form_action = myform.options[:action].present? ? myform.options[:action] : (obj.new_record? ? send("kobe_#{obj.class.to_s.tableize}_path") : send("kobe_#{obj.class.to_s.tableize}_path", obj) )
    form_method = myform.obj.new_record? ? "post" : "patch"
    myform.html_code << form_tag(form_action, method: myform.options[:method], class: 'sky-form no-border', id: myform.options[:form_id]).to_str

    # 自动生成标题，根据model中的Mname
    if myform.options[:title].blank?
      # {title: false} 表示不需要标题
      if myform.options[:title]!= false
        t = myform.obj.new_record? ? "新增" : "修改"
        t = t + myform.obj.class.const_get(:Mname) if myform.obj.class.const_defined?(:Mname)
        myform.html_code << "<div class='headline'><h2><strong>#{t}</strong></h2></div>"
      end
    else
      # 自定义标题
      myform.html_code << "<div class='headline'><h2><strong>#{myform.options[:title]}</strong></h2></div>"
    end
  end

  def set_input_part(myform)
    myform.html_code << myform.get_input_part
  end

  def set_upload_part(myform)
    opts ||= {}
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

  # 设置主从表金额
  def set_total_part(myform)
    # 附加费用
    if myform.obj.class.respond_to?(:fee_xml)
      str = myform.get_input_str(myform.obj.class.fee_xml, myform.obj, myform.table_name, 3)
      myform.html_code << content_tag(:div, raw(str.html_safe).html_safe, :class=>'tag-box tag-box-v1')
      tmp = %Q{
        $("input#" + master_table_names + "_deliver_fee").live('change blur',function(){sum_calc_total(master_table_names,slave_table_names);});
        $("input#" + master_table_names + "_other_fee").live('change blur',function(){sum_calc_total(master_table_names,slave_table_names);});
      }
    end
    myform.html_code << show_total_part
    myform.html_code << %Q|
      <script type="text/javascript">
      $(function() {
        var master_table_names = "#{myform.table_name}";
        var slave_table_names = "#{myform.slave_table_name}";
        //影响小计的输入框有变动
        $("input[name^='"+slave_table_names+"[price]']").live('change blur',function(){input_blur($(this),master_table_names,slave_table_names)});
        $("input[name^='"+slave_table_names+"[quantity]']").live('change blur',function(){input_blur($(this),master_table_names,slave_table_names)});
        $("input[name^='"+slave_table_names+"[total]']").live('change blur',function(){sum_calc_total(master_table_names,slave_table_names);});
        sum_calc_total(master_table_names,slave_table_names);
        #{tmp}
      });
      </script>
    |
  end

  # 根据数组计算单表的金额
  def set_total_by_array(myform)
    arr = myform.options[:show_total]
    myform.options[:total_name] ||= "总计"
    if arr.is_a?(Array)
      myform.html_code << show_total_part(0, myform.options[:total_name])
      tmp = ""
      arr.each do |a|
        tmp << %Q{
          $("input##{myform.table_name}_#{a}").live('change blur',function(){
            sum_total_by_array("#{myform.table_name}", #{arr});
          });
        }
      end
      myform.html_code << %Q|
        <script type="text/javascript">
        $(function() {
          #{tmp}
        });
        </script>
      |
    end
  end

end
