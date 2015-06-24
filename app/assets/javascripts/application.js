// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require plugins/jquery-1.10.2.min
//= require plugins/jquery-migrate-1.2.1.min
//= require jquery_ujs 
//= require plugins/bootstrap/js/bootstrap.min
//= require plugins/back-to-top
//= require plugins/jquery.query
//= require plugins/dialog-min
//= require plugins/fancybox/source/jquery.fancybox.pack
//= require app
//= require form
//= require plugins/jquery.dragsort-0.5.2.min


$(function() {

	// 初始化
	App.init();
	// 初始化 图片展示
	App.initFancybox();

	// 状态筛选,用于list列表页面
	$(".status_filter").on('click',function(){
		var newUrl = $.query.REMOVE("page");
		newUrl = $.query.set("status_filter", $(this).attr("value")).toString(); //如果存在会替换掉存在的参数的值
		location.href = newUrl;
	});
	// 日期筛选,用于list列表页面
	$(".date_filter").on('click',function(){
		var newUrl = $.query.REMOVE("page");
		newUrl = $.query.set("date_filter", $(this).attr("value")).toString(); //如果存在会替换掉存在的参数的值
		location.href = newUrl;
	});

  // 增加明细
  var add_max = -1;
  var add_html = "";

  function init_add_content(){
    add_max = $("#add_content").siblings(".details_part").length;
    add_html = $("#add_content").html();
    $("#add_content").empty();
    return add_max;
  }

  $('body').on("click","#add_button",function(){
    if (add_html == ""){
      init_add_content();
    }
    add_max += 1;
    $("#add_content").before(add_html.replaceAll("_orz_",add_max));
  });

  // 折叠/展开明细
  // $('body').on("click","div.details_part span i.fa",ToggleDetails);
  $('body').on("click","i.fa-chevron-circle-down",ToggleDetails);
  $('body').on("click","i.fa-chevron-circle-right",ToggleDetails);

  // FORM提交前先展开所有明细，不然表单不校验
  $('body').on("submit","form.sky-form",function(){
    $("#add_content").empty();
    $("div.details_part span i.fa-chevron-circle-right").each(ToggleDetails);
  });

});

// 折叠/展开明细
function ToggleDetails(){
  $(this).toggleClass("fa-chevron-circle-down");
  $(this).toggleClass("fa-chevron-circle-right");
  $(this).parent().next().slideToggle("fast");
}

// 验证表单字段规则
function validate_form_rules (form_id,form_rules,form_messages) {
	form_messages = form_messages || {};
	$(form_id).validate({
		rules: form_rules,
		messages: form_messages,
		errorPlacement: function(error, element)
		{
			error.insertAfter(element.parent());
		}
	});
};

// 手动关闭提示弹框
function flash_dialog (content) {
	dialog({
    title: '提示',
    content: content,
    fixed: true //  开启固定定位
	}).show();
};
// 自动关闭提示框
function tips_dialog (content) {
	var d = dialog({
    content: content,
    quickClose: true, // 点击空白处关闭提示框
    fixed: true
	});
	d.show();
	setTimeout(function () {
	    d.close().remove();
	}, 5000);
};
// 确认弹框
function confirm_dialog (content,ok_function) {
	dialog({
    content: content,
    fixed: true,
    okValue: '确定',
    ok: ok_function,
    cancelValue: '取消',
    cancel: function () {}
	}).show();
}








// 通用函数

//格式化成两位小数 如果没有小数不补0，如果要补0的话用src.toFixed(2)
function formatFloat(src, pos){
    return Math.round(src*Math.pow(10, pos))/Math.pow(10, pos);
//    return src.toFixed(4)
}
//格式化小数 等于0时不补零，否则补零
function FormatFloat(src, pos){
    if(src==0){return 0;}
    else{
        return src.toFixed(pos);
    }

}

//将字符串转换成对象，避免使用eval
function parseObj( strData ){
	return (new Function( "return " + strData ))();
}

//计算字符长度区分中英文
function strlen(value){
	var _tmp = value;
	var _length = 0;
	for (var i = 0; i < _tmp.length; i++) {
		if (_tmp.charCodeAt(i) > 255) {
			_length = _length + 2;
		}
		else {
			_length++;
		}
	}
	return _length;
}

//每列的合计
function sum_tr(i){
	var sum=0;
	var v = $(".product_tr").find("td:eq("+i+")").each(function(){
	 //   $(this).css("text-align","right");
		if ( !isNaN($(this).text()) && ($(this).text() != '')){
			sum += parseFloat($(this).text());
		}
	});
	return formatFloat(sum,2);
}

/**替换全部字符，使用方法：
var teststr ="asdfasdfasdfasdfasdfasdfasdfasdfasdf";
alert(teststr.replaceAll("as","df"));
**/
String.prototype.replaceAll = function(reallyDo, replaceWith, ignoreCase) {
     if (!RegExp.prototype.isPrototypeOf(reallyDo)) {
         return this.replace(new RegExp(reallyDo, (ignoreCase ? "gi": "g")), replaceWith);
    } else {
         return this.replace(reallyDo, replaceWith);
     }
}

//求数组的最大值
Array.prototype.max = function() {
    return Math.max.apply({},this)

}
//求数组的最小值
Array.prototype.min = function() {
    return Math.min.apply({},this)

}

// 弹出提示框  
function dialog_alter(ct){
	art.dialog({
		title: '提示',
		content:ct,
		height:89
	})
}

//大写金额
function cmycurd(num){  //转成人民币大写金额形式
  var str1 = '零壹贰叁肆伍陆柒捌玖';  //0-9所对应的汉字
  var str2 = '万仟佰拾亿仟佰拾万仟佰拾元角分'; //数字位所对应的汉字
  var str3;    //从原num值中取出的值
  var str4;    //数字的字符串形式
  var str5 = '';  //人民币大写金额形式
  var i;    //循环变量
  var j;    //num的值乘以100的字符串长度
  var ch1;    //数字的汉语读法
  var ch2;    //数字位的汉字读法
  var nzero = 0;  //用来计算连续的零值是几个

  num = Math.abs(num).toFixed(2);  //将num取绝对值并四舍五入取2位小数
  str4 = (num * 100).toFixed(0).toString();  //将num乘100并转换成字符串形式
  j = str4.length;      //找出最高位
  if (j > 15){return '溢出';}
  str2 = str2.substr(15-j);    //取出对应位数的str2的值。如：200.55,j为5所以str2=佰拾元角分

  //循环取出每一位需要转换的值
  for(i=0;i<j;i++){
    str3 = str4.substr(i,1);   //取出需转换的某一位的值
    if (i != (j-3) && i != (j-7) && i != (j-11) && i != (j-15)){    //当所取位数不为元、万、亿、万亿上的数字时
   if (str3 == '0'){
     ch1 = '';
     ch2 = '';
  nzero = nzero + 1;
   }
   else{
     if(str3 != '0' && nzero != 0){
       ch1 = '零' + str1.substr(str3*1,1);
          ch2 = str2.substr(i,1);
          nzero = 0;
  }
  else{
    ch1 = str1.substr(str3*1,1);
          ch2 = str2.substr(i,1);
          nzero = 0;
        }
   }
}
else{ //该位是万亿，亿，万，元位等关键位
      if (str3 != '0' && nzero != 0){
        ch1 = "零" + str1.substr(str3*1,1);
        ch2 = str2.substr(i,1);
        nzero = 0;
      }
      else{
     if (str3 != '0' && nzero == 0){
          ch1 = str1.substr(str3*1,1);
          ch2 = str2.substr(i,1);
          nzero = 0;
  }
        else{
    if (str3 == '0' && nzero >= 3){
            ch1 = '';
            ch2 = '';
            nzero = nzero + 1;
       }
       else{
      if (j >= 11){
              ch1 = '';
              nzero = nzero + 1;
   }
   else{
     ch1 = '';
     ch2 = str2.substr(i,1);
     nzero = nzero + 1;
   }
          }
  }
   }
}
    if (i == (j-11) || i == (j-3)){  //如果该位是亿位或元位，则必须写上
        ch2 = str2.substr(i,1);
    }
    str5 = str5 + ch1 + ch2;
  
    if (i == j-1 && str3 == '0' ){   //最后一位（分）为0时，加上“整”
      str5 = str5 + '整';
    }
  }
  if (num == 0){
    str5 = '零元整';
  }
  return str5;
}