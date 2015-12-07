//= require application
//= require plugins/counter/jquery.counterup.min
//= require plugins/image-hover/modernizr
//= require plugins/image-hover/touch


//= require shop/forms/product-quantity
//= require shop/plugins/master-slider
//= require shop/shop.app
//= require shop/master-slider/quick-start/masterslider/masterslider.min
//= require shop/master-slider/quick-start/masterslider/jquery.easing.min

//= require my97/WdatePicker


$(function(){
  // 检查是否同登陆以显示价格
  var ids = $(".price_div").map(function(){ return $(this).attr("id").split("_")[2]}).get().join(",");
  $.ajax({
    type: "get",
    dataType: "json",
    url: "/check_login",
    data: "pids=" + ids,
    success: function(data) {
      if(data.success){
        // 列表商品价格
        $.each(data.rs, function(i, d){
          $("#price_div_" + d.id + " b.b_m").html(d.market_price).show();
          $("#price_div_" + d.id + " b.b_b").html(d.bid_price).show();
        })
      }else{
        $(".b_m").show();
        $(".b_b").show();
      }
    }
  });
})