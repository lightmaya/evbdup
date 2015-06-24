var Datepicker = function () {

    return {
        
        //Datepickers
        initDatepicker: function () {
	        // Regular datepicker
	        $('.date_select').datepicker({
	            dateFormat: 'yy-mm-dd',
	            prevText: '<i class="fa fa-angle-left"></i>',
	            nextText: '<i class="fa fa-angle-right"></i>'
	        });
	        
	        // Date range
	        $('.start_date').datepicker({
	            dateFormat: 'dd.mm.yy',
	            prevText: '<i class="fa fa-angle-left"></i>',
	            nextText: '<i class="fa fa-angle-right"></i>',
	            onSelect: function( selectedDate )
	            {
	                $('.finish_date').datepicker('option', 'minDate', selectedDate);
	            }
	        });
	        $('.finish_date').datepicker({
	            dateFormat: 'dd.mm.yy',
	            prevText: '<i class="fa fa-angle-left"></i>',
	            nextText: '<i class="fa fa-angle-right"></i>',
	            onSelect: function( selectedDate )
	            {
	                $('.start_date').datepicker('option', 'maxDate', selectedDate);
	            }
	        });
        }

    };
}();