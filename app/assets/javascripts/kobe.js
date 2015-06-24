//= require plugins/jquery.ztree.all-3.5
//= require ztree_show

// 全选、取消全选的事件  
function selectAll(){  
    if ($("#check_all").attr("checked")) {  
        $(":checkbox").attr("checked", true);  
    } else {  
        $(":checkbox").attr("checked", false);  
    }  
};
// 子复选框的事件  
function setSelectAll(){  
    //当没有选中某个子复选框时，SelectAll取消选中  
    if (!$(this).checked) {  
        $("#check_all").attr("checked", false);  
    }  
    var chsub = $(".list_table tbody input[type='checkbox']").length; //获取checkbox的个数  
    var checkedsub = $(".list_table tbody input[type='checkbox']:checked").length; //获取选中的checkbox的个数  
    if (checkedsub == chsub) {  
        $("#check_all").attr("checked", true);  
    }else {
        $("#check_all").attr("checked", false); 
    }
};

// Ajax 正在加载中。。。
function ajax_before_send(div){
    $(div).html('<div class="ajax_loading">正在加载中，请稍后...</div>');
}

// Ajax加载页面
function show_content(url,div,upload_form_id) {
    $.ajax({
        type: "get",
        url: url,
        beforeSend: ajax_before_send(div),
        success: function(data) {
            $(div).html(data);
            // 如果有上传附件 加载上传的js
            if(upload_form_id != undefined){
                upload_files(upload_form_id);
            }
            // 如果有form 加载日期控件
            if($(div).has('form').length != 0) {
                Datepicker.initDatepicker();
            }
        }
    });
}

// 弹框modal_dialog ajax加载显示 
// 设置modal-header的title并Ajax加载modal-body
function modal_dialog_show(title,ajax_url,modal_dialog_div,upload_form_id) {
    $(modal_dialog_div + " .modal-header .modal-title").html(title);
    show_content(ajax_url, modal_dialog_div + " .modal-body", upload_form_id);
}

// 更多操作,用于list列表页面,主要用于批量操作
$(".more_actions").on('click',function(){
    //获取选中的checkbox的个数
    var checked = $(".list_table tbody input[type='checkbox']:checked"); 
    if (checked.length == 0) {
        flash_dialog("请选择至少一项再进行操作！");
        return false;
    }else {
        $('#more_actions_form').attr("action", this.attributes["value"].value);
        $("#more_actions_dialog .modal-header .modal-title").html(this.innerHTML);
        var id_array = checked.map(function(){ return $(this).val(); }).get().join(',');
        $('#more_actions_form').append("<input type='hidden' name='id_array' value='"+ id_array +"'/>")
        $('#more_actions_dialog').modal();
    }
});