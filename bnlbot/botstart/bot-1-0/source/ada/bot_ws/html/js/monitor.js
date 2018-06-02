
var Timer;
var Cnt;


//bnl
$.makeTable = function (mydata) {
    var table = $('<table>');
    var tblHeader = "<thead><tr>";
    for (var k in mydata[0]) tblHeader += "<th>" + k + "</th>";
    tblHeader += "</tr></thead>";
    $(tblHeader).appendTo(table);
    $.each(mydata, function (index, value) {
        var TableRow = "<tr>";
        $.each(value, function (key, val) {
            console.log("key: " + key + " val: " + val);
            if (typeof val == "string" && key == "betname") {
              TableRow += "<td>" + val.slice(0,18) + "</td>";
            } else if (typeof val == "string" && key == "betplaced") {
              TableRow += "<td>" + val.slice(12,24) + "</td>";
            } else {            
              TableRow += "<td>" + val + "</td>";
            }
        });
        TableRow += "</tr>";
        $(table).append( TableRow);
    });
    //$(table).append( '</table>');

    return ($(table));
};


function Do_Ajax_Bets() {
  var d = new Date();
  var n = d.getTime(); 

  $.ajax({url: 'https://betbot.nonobet.com',
      data: {'context' : 'todays_bets',
             'dummy' : n },
      type: 'get',                   
      async: 'true',
      dataType: 'json',
      beforeSend: function() {
          // This callback function will trigger before data is sent
          console.log("Do_Ajax_Bets.beforeSend");
          //$.mobile.loading( "show" );
      },
      complete: function() {
          // This callback function will trigger on data sent/received complete
          console.log("Do_Ajax_Bets.complete");
         // $.mobile.loading( "hide" );
      },
      success: function (reply) {
          console.log("Do_Ajax_Bets.success");
          if(reply.result == "OK") {
             console.log("Do_Ajax_Bets.success OK");
             
             
            // //fill the table
            var table = $.makeTable(reply.datatable);
            $('#bets').html(table).trigger('create')
             
             
          } else {
             console.log("Do_Ajax_Bets.success NOT OK");
          }
      },
      error: function (request,error) {
          console.log("Do_Ajax_Bets.error " + error);
      }
  });                   

}

function Do_Ajax_Today() {
  var d = new Date();
  var n = d.getTime(); 

  $.ajax({url: 'https://betbot.nonobet.com',
      data: {'context' : "todays_total",
             'dummy' : n },
      type: 'get',                   
      async: 'true',
      dataType: 'json',
      beforeSend: function() {
          // This callback function will trigger before data is sent
          console.log("Do_Ajax_Today.beforeSend");
          //$.mobile.loading( "show" );
      },
      complete: function() {
          // This callback function will trigger on data sent/received complete
          console.log("Do_Ajax_Today.complete");
         // $.mobile.loading( "hide" );
      },
      success: function (reply) {
          console.log("Do_Ajax_Today.success");
          if(reply.result == "OK") {
             console.log(" Do_Ajax_Today.success OK");
             
            // $('#todays_total').empty();
             $('#today').text("Resultat:"+ reply.total + " kr" );
             
             
          } else {
             console.log("Do_Ajax_Today.success NOT OK");
          }
      },
      error: function (request,error) {
          console.log("Do_Ajax_Today.error " + error);
      }
  });                   

}

function Run_All() {
  console.log("Run_All start");
  var pBar = document.getElementById('pb');
  Cnt = Cnt +1;
  
  var percent = Cnt ;
  console.log("Run_All" + Cnt + "-" + percent );
  
  if (Cnt == 100) {
   // Do_Ajax_Race();
    Do_Ajax_Today();
    Do_Ajax_Bets();
  //  Do_Ajax_Seven_Days()
  //  Do_Ajax_Twenty_Eigth_Days()
    Cnt = 0;
    console.log("Run_All stop 1");
  } else {
    pBar.value = percent;
  }
  console.log("Run_All stop 2");
}


function Start_Timer () {
  console.log("Start_Timer start");
  Timer = setInterval(Run_All, 1000);
  console.log("Start_Timer stop");
}


function Do_Login() {

 $.ajax({url: 'https://betbot.nonobet.com',
     data: $('#loginform').serialize(),
     type: 'post',                   
     async: 'true',
     dataType: 'json',
     beforeSend: function() {
         // This callback function will trigger before data is sent
         console.log("Do_Login.beforeSend");
        // $.mobile.loading( "show" );
     },
     complete: function() {
         // This callback function will trigger on data sent/received complete
         console.log("Do_Login.complete");
        // $.mobile.loading( "hide" );
     },
     success: function (reply) {
         console.log("success");
         if(reply.result == "OK") {
            console.log("Do_Login success OK");
            Start_Timer()                         
         } else {
            console.log("Do_Login - success NOT OK");
         }
     },
     error: function (request,error) {
         console.log("Do_Login.error " + error);
     }
 });                   

}

function Do_Start() {
     //call by window.onload 
     console.log("onReady Start");
     Cnt = 95;
     //start timer ...
    // Start_Timer();
     Do_Login();
     
     console.log("onReady Stop");
}


$(document).ready(function(){
  Do_Start();  
});
  

