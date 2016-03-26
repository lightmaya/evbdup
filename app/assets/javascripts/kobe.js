//= require plugins/jquery.ztree.all-3.5
//= require ztree_show
//= require plugins/counter/waypoints.min
//= require plugins/counter/jquery.counterup.min
//= require plugins/jquery.mCustomScrollbar.concat.min



// Ajax 正在加载中。。。
function ajax_before_send(div){
    $(div).html('<div class="ajax_loading">正在加载中，请稍后...</div>');
}

// Ajax加载页面
function show_content(url,div,upload_form_id) {
    ajax_get_show(url,'',div,function(data){
        $(div).html(data);
        // 如果有上传附件 加载上传的js
        if(upload_form_id != undefined){
            upload_files(upload_form_id);
        }
        // 如果有form 加载日期控件
        if($(div).has('form').length != 0) {
            Datepicker.initDatepicker();
        }
    })
}
// post 加载页面
function ajax_post_show(url,data,div,success_function) {
    $.ajax({
        type: "post",
        url: url,
        data: data,
        beforeSend: ajax_before_send(div),
        success: success_function,
        error: function(data) { $(div).html(data.responseText); }
    });
}
// get 加载页面
function ajax_get_show(url,data,div,success_function) {
    $.ajax({
        type: "get",
        url: url,
        data: data,
        beforeSend: ajax_before_send(div),
        success:success_function,
        error: function(data) { $(div).html(data.responseText); }
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

// 生成表单时 有xml类型的字段 使用ajax提交xml的node
function ajax_submit_or_remove_xml_column (url,data,submit_div) {
    var value = $(submit_div + " input").val();
    if (value != "" || value != undefined) { data["column_value"] = value; };
    ajax_post_show(url,data,'',function (data) {
        $(submit_div).prevAll().remove();
        $(submit_div).before(data);
        if (data!="") {$(submit_div + " input").removeClass("required").val("");};
    });
};

// 下订单前填写预算 上传附件
function show_budget_form(budget_id){
    var url = "/kobe/shared/get_budget_form"
    if (isEmpty(budget_id)){
        var title = "填写预算"
    } else {
        var title = "修改预算"
        url += ("?id=" + budget_id)
    }
    modal_dialog_show(title, url, "#budget_dialog", "budget_form_fileupload")
};

// 保存填写的预算并给预算金额、budget_id 赋值
function get_budget(obj_id, input_id, budget_id){
    var upload_ids = $('form#budget_form_fileupload tr.template-download .preview[file_id]').map(function() {
        return $(this).attr('file_id');
    }).get().join(',');

    var total = $("#budget_dialog #budgets_total").val();
    var summary = $("#budget_dialog #budgets_summary").val();

    $.ajax({
        type: "post",
        url: "/kobe/shared/save_budget",
        data: { id: obj_id, uids: upload_ids, total: total, summary: summary },
        success: function(data){
            $("#" + input_id).val(data["total"]);
            $("#" + budget_id).val(data["id"]);
            $("#budget_dialog").modal('hide');
            return false;
        }
    });
};
