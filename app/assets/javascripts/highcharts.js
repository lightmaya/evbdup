//= require plugins/jquery.min
//= require plugins/highcharts_for_tj/highcharts

var highcharts_credits = {style:{fontSize: '12px'},text:'中储粮服务网',href: 'http://fwgs.sinograin.com.cn'};

$(function () {

    // Make monochrome colors and set them as default for all pies
    Highcharts.getOptions().plotOptions.pie.colors = (function () {
    	var colors = [],
    	base = Highcharts.getOptions().colors[0],
    	i;

    	for (i = 0; i < 10; i += 1) {
            // Start out with a darkened base color (negative brighten), and end
            // up with a much brighter color
            colors.push(Highcharts.Color(base).brighten((i - 3) / 7).get());
          }
          return colors;
        }());
  });

// 柱状图
function get_column(div_id,title,data)
{  
  $('#'+ div_id).highcharts({
    chart: { type: 'column' },
    credits: highcharts_credits,
    title: { text: title },
    xAxis: {
      type: 'category',
      labels: { style: { fontSize: '13px' } }
    },
    yAxis: {
      min: 0,
      title: { text: '金额 (元)' }
    },
    legend: { enabled: false },
    tooltip: { pointFormat: '金额: <b>{point.y:.2f} 元</b>' },
    series: [{ data: data }]
  });
}
