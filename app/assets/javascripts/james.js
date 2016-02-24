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
  var product_ids = $(".product_price_div").map(function(){ return $(this).attr("id").split("_")[3]}).get().join(",");
  $.ajax({
    type: "get",
    dataType: "json",
    url: "/check_login",
    data: "pids=" + product_ids,
    success: function(data) {
      if(data.success){
        $.each(data.rs, function(i, d){
          $("#bid_price_" + d.id).html("入围价格： <span class='color-red font-bold font-size-16'>" + d.bid_price + "</span>" + ($(".product_price_div").length > 1 ? "" : " [ 可向下议价 ]")).show();
          $("#market_price_" + d.id).html("市场价格： <span class='line-through'>" + d.market_price + "</span>").show();
        });
      }else{
        $.each(product_ids.split(","), function(i, d) {
          $("#login_tip_" + d).show();
        });
      }
    }
  });

})
