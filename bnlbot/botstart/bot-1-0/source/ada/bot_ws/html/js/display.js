



function Do_Ajax2() {
  $.ajax({url: 'https://betbot.nonobet.com',
      data: {'context' : "todays_total"},
      type: 'get',                   
      async: 'true',
      dataType: 'json',
      beforeSend: function() {
          // This callback function will trigger before data is sent
          console.log("Do_Ajax2.beforeSend");
          //$.mobile.loading( "show" );
      },
      complete: function() {
          // This callback function will trigger on data sent/received complete
          console.log("Do_Ajax2.complete");
         // $.mobile.loading( "hide" );
      },
      success: function (reply) {
          console.log("Do_Ajax2.success");
          if(reply.result == "OK") {
             console.log(" Do_Ajax2.success OK");
             
            // $('#todays_total').empty();
             $('#todays_total').text("Resultat:"+ reply.total + " kr" );
             
            // //fill the table
            // var table = $.makeTable(reply.datatable);
            // $('#viewer_content').html(table).trigger('create')
             
             
          } else {
             console.log("Do_Ajax2.success NOT OK");
          }
      },
      error: function (request,error) {
          console.log("Do_Ajax2.error " + error);
      }
  });                   

}




function Do_Ajax1() {

 $.ajax({url: 'https://betbot.nonobet.com',
     data: $('#loginform').serialize(),
     type: 'post',                   
     async: 'true',
     dataType: 'json',
     beforeSend: function() {
         // This callback function will trigger before data is sent
         console.log("Do_Ajax1.beforeSend");
        // $.mobile.loading( "show" );
     },
     complete: function() {
         // This callback function will trigger on data sent/received complete
         console.log("Do_Ajax1.complete");
        // $.mobile.loading( "hide" );
     },
     success: function (reply) {
         console.log("success");
         if(reply.result == "OK") {
            console.log("Do_Ajax 1 success OK");
            Do_Ajax2()                         
         } else {
            console.log("Do_Ajax1 - success NOT OK");
         }
     },
     error: function (request,error) {
         console.log("Do_Ajax2.error " + error);
     }
 });                   

}


$(document).ready(function(){

     console.log("onReady Start");
     
     //start timer ...
     
     Do_Ajax1();
     
     console.log("onReady Stop");
     
});  

