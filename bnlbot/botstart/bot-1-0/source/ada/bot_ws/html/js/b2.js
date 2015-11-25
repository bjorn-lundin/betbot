  //track changes in radiobtn clicks
var selectedRadio ='bnl'; 
var context = 'todays_bets'



//bnl
$.makeTable = function (mydata) {
    var table = $('<table data-role="table" data-mode="columntoggle" class="ui-responsive" id="datatable">');
    var tblHeader = "<thead><tr>";
    for (var k in mydata[0]) tblHeader += "<th>" + k + "</th>";
    tblHeader += "</tr></thead>";
    $(tblHeader).appendTo(table);
    $.each(mydata, function (index, value) {
        var TableRow = "<tr>";
        $.each(value, function (key, val) {
            TableRow += "<td>" + val + "</td>";
        });
        TableRow += "</tr>";
        $(table).append( TableRow);
    });
    return ($(table));
};



$(document).ready(function(){
     $('#loginform input').on('change', function() {
         selectedRadio = $('input[name="username"]:checked', '#loginform').val();
         console.log("selectedRadio " + selectedRadio);
     });
     
     $(document).on('click', '#submit', function() { // catch the form's submit event
             // Send data to server through the Ajax call
             // action is functionality we want to call and outputJSON is our data
                 $.ajax({url: 'login',
                     data: $('#loginform').serialize(),
                     type: 'post',                   
                     async: 'true',
                     dataType: 'json',
                     beforeSend: function() {
                         // This callback function will trigger before data is sent
                         console.log("beforeSend");
                         $.mobile.loading( "show" );
                     },
                     complete: function() {
                         // This callback function will trigger on data sent/received complete
                         console.log("complete");
                         $.mobile.loading( "hide" );
                     },
                     success: function (reply) {
                         console.log("success");
                         if(reply.result == "OK") {
                            console.log("success OK");
                            $.mobile.changePage("#menu");                         
                         } else {
                            console.log("success NOT OK");
                         }
                     },
                     error: function (request,error) {
                         console.log("error " + error);
                     }
                 });                   
         return false; // cancel original event to prevent form submitting
     });    

     $('#todays').on('tap', function() {
         context ='todays_bets';
         console.log("todays - context " + context);
     });
     
     $('#yesterday').on('tap', function() {
         context ='yesterdays_bets';
         console.log("yesterday - context " + context);
     });
     
     $('#thisweek').on('tap', function() {
         context ='thisweeks_bets';
         console.log("thisweek - context " + context);
     });
     
     $('#lastweek').on('tap', function() {
         context ='lastweeks_bets';
         console.log("lastweek - context " + context);
     });
     
    
     $(document).on("pageshow","#viewer",function(){
       // var para = "<p id='tobedeleted'>ny kod från event</p>";
       // $('#tobedeleted').empty();
       // $('#viewer_content').append(para);
       $.ajax({url: '/0',
           data: {'context' : context},
           type: 'get',                   
           async: 'true',
           dataType: 'json',
           beforeSend: function() {
               // This callback function will trigger before data is sent
               console.log("beforeSend");
               $.mobile.loading( "show" );
           },
           complete: function() {
               // This callback function will trigger on data sent/received complete
               console.log("complete");
               $.mobile.loading( "hide" );
           },
           success: function (reply) {
               console.log("success");
               if(reply.result == "OK") {
                  console.log("success OK");
                  
                  $('#viewer_content').empty();
                  $('#viewer_content').append("<p id='total'></p>");
                  $('#total' ).text( "Totalt: " + reply.total + " kr" );
                  
                  //fill the table
                  var table = $.makeTable(reply.datatable);
                  $(table).appendTo("#viewer_content");  
                  
                  
               } else {
                  console.log("success NOT OK");
               }
           },
           error: function (request,error) {
               console.log("error " + error);
           }
       });                   
       
       
     });     
     
     
});  

