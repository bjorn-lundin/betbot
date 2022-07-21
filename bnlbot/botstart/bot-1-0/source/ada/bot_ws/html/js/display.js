
var Timer;
var Cnt;
//var URL=https://lundin.duckdns.org
//var URL=http://192.168.1.229:9080
var URL=http://lundin.duckdns.org:9080

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


function Do_Ajax3() {
  var d = new Date();
  var n = d.getTime();

  $.ajax({url: URL,
      data: {'context' : "weekly_total",
             'dummy' : n },
      type: 'get',
      async: 'true',
      dataType: 'json',
      beforeSend: function() {
          // This callback function will trigger before data is sent
          console.log("Do_Ajax3.beforeSend");
          //$.mobile.loading( "show" );
      },
      complete: function() {
          // This callback function will trigger on data sent/received complete
          console.log("Do_Ajax3.complete");
         // $.mobile.loading( "hide" );
      },
      success: function (reply) {
          console.log("Do_Ajax3.success");
          if(reply.result == "OK") {
             console.log("Do_Ajax3.success OK");


            // //fill the table
            var table = $.makeTable(reply.datatable);
            $('#weekly_totals').html(table).trigger('create')


          } else {
             console.log("Do_Ajax3.success NOT OK");
          }
      },
      error: function (request,error) {
          console.log("Do_Ajax3.error " + error);
      }
  });

}

function Do_Ajax2() {
  var d = new Date();
  var n = d.getTime();

  $.ajax({url: URL,
      data: {'context' : "todays_total",
             'dummy' : n },
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


          } else {
             console.log("Do_Ajax2.success NOT OK");
          }
      },
      error: function (request,error) {
          console.log("Do_Ajax2.error " + error);
      }
  });

}

function Run_All() {
  var pBar = document.getElementById('pb');
  //console.log("Run_All start");
  Cnt = Cnt +1;

  var percent = Cnt ;
 // console.log("Run_All" + Cnt + "-" + percent );

  if (Cnt == 100) {
    Do_Ajax2()
    Do_Ajax3()
    Cnt = 0;
  } else {
    pBar.value = percent;
  }
 // console.log("Run_All stop");
}


function Start_Timer () {
  console.log("Start_Timer start");
  Timer = setInterval(Run_All, 1000);
  console.log("Start_Timer stop");
}


function Do_Login() {

 $.ajax({url: URL,
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
     Cnt = 98;
     console.log("onReady Start");
     document.getElementById("loginform").style.display="none";
     //start timer ...

     Do_Login();

     console.log("onReady Stop");
}


$(document).ready(function(){
  Do_Start();
});



