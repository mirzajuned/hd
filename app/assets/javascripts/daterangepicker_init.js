function daterangepicker_init(target,max_range) {
  var cb = function(start, end, label) {
    $('#'+target+' span').html(start.format('MMMM D, YYYY') + ' - ' + end.format('MMMM D, YYYY'));
  }
  var optionSet = {
                    startDate: moment().subtract(6, 'days'),
                    endDate: moment(),
                    minDate: '01/01/2014',
                    maxDate: moment(),
                    dateLimit: { days: max_range },
                    showDropdowns: true,
                    showWeekNumbers: true,
                    timePicker: false,
                    ranges: {
                       'Today': [moment(), moment()],
                       'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
                       'Last 7 Days': [moment().subtract(6, 'days'), moment()],
                       'Last 30 Days': [moment().subtract(29, 'days'), moment()],
                       'This Month': [moment().startOf('month'), moment().endOf('month')],
                       'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
                    },
                    opens: 'left',
                    buttonClasses: ['btn'],
                    applyClass: 'btn-small btn-primary',
                    cancelClass: 'btn-small',
                    format: 'DD-MM-YYYY',
                    separator: ' to '
                  };
  $('#'+target+' span').html(moment().subtract(7, 'days').format('MMMM D, YYYY') + ' - ' + moment().format('MMMM D, YYYY'));
  $('#'+target).daterangepicker(optionSet,cb);
}
