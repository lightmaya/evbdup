//= require plugins/sky-forms/version-2.0.1/js/jquery.form.min
//= require plugins/sky-forms/version-2.0.1/js/jquery.validate.min
//= require plugins/sky-forms/version-2.0.1/js/additional-methods.min
//= require plugins/sky-forms/version-2.0.1/js/jquery.maskedinput.min
//= require plugins/sky-forms/version-2.0.1/js/jquery-ui.min
//= require plugins/masking
//= require plugins/datepicker
//= require plugins/dialog-select
//= require jquery-fileupload
//
function upload_files(form_id){
	var url = $("#" + form_id).prop("action");
  if (url.lastIndexOf("master_id") > 0){
    $.getJSON(url, function(files){
      var fu = $("#" + form_id).data('blueimpFileupload'), template;
      fu._adjustMaxNumberOfFiles(-files.length);
      console.log(files);
      template = fu._renderDownload(files).appendTo($('#'+ form_id +' .files'));
      fu._reflow = fu._transition && template.length && template[0].offsetWidth;
      template.addClass('in');
      $('#loading').remove();
    });
  }

}

$(function() {
  // Masking.initMasking();
  // 日期选择
  Datepicker.initDatepicker();
  // 上传附件
  $('form.fileupload_form').each(function(){
  	upload_files($(this).attr("id"));
	});

  // 验证 通过类来验证
  jQuery.validator.addClassRules({
    required: {required: true},
    email: {email: true},
    url: {url: true},
    date: {date: true},
    dateISO: {dateISO: true}, 
    number: {number: true},
    digits: {digits: true},  
    minlength_6: {minlength: 6},
    maxlength_800: {maxlength: 800},
    rangelength_6_20: {rangelength: [6,20]},
    min_1: {min: 1},
    max_100: {max: 100},
    range_1_1000: {range: [1,1000]}
  });

    // $('.特殊类').each(function() {
    //   $(this).rules('add', {
    //       required: true,
    //       number: true,
    //       messages: {
    //           required:  "必填项",
    //           number:  "必须是数字"
    //       }
    //   });
    // });
});