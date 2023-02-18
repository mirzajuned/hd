require.config({
  paths: {
    jquery: 'jquery.min',
    underscore: 'underscore',
    backbone: 'backbone'
  }

});

require([
  // Load our app module and pass it to our definition function
  'reports/reports',
], function(Reports){
  // The "app" dependency is passed in as "App"
  $(document).ready(function(){
    Reports.initialize();
  })
});