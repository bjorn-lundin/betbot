
var Timer;
var Cnt;
//var URL="https://betbot.nonobet.com"
//var URL="http://192.168.1.6:9080"
var URL ="https://lundin.duckdns.org"
var login_again;

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
              //          1         2         3
              //0123456789012345678901234567890123456789
              //horse_back_1_50_01_1_2_plc_1_06
              TableRow += "<td>" + val.slice(11) + "</td>";
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

function Do_Ajax_Table(context) {
  var d = new Date();
  var n = d.getTime();

  $.ajax({url: URL,
      data: {'context' : context,
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
             console.log("Do_Ajax_Bets.success OK\n" + reply.datatable);

            // //fill the table
            var table = $.makeTable(reply.datatable);
            if (context == 'sum_todays_bets') {
              $('#sum_todays_bets').html(table).trigger('create')
            }

            if (context == 'sum_7_days_bets') {
              $('#sum_7_days_bets').html(table).trigger('create')
            }

            if (context == 'sum_thisweeks_bets') {
              $('#sum_thisweeks_bets').html(table).trigger('create')
            }

            if (context == 'sum_total_bets') {
              $('#sum_total_bets').html(table).trigger('create')
            }

            if (context == 'starttimes') {
              $('#starttimes').html(table).trigger('create')
            }

          } else {
             console.log("Do_Ajax_Bets.success NOT OK");
          }
      },
      error: function (request,error) {
          console.log("Do_Ajax_Bets.error " + error + "\context:" + context);
      }
  });

}

function Do_Ajax_Today(context) {
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
          console.log("Do_Ajax_Today.beforeSend");
      },
      complete: function() {
          // This callback function will trigger on data sent/received complete
          console.log("Do_Ajax_Today.complete");
      },
      success: function (reply) {
          console.log("Do_Ajax_Today.success");
          if(reply.result == "OK") {
             console.log(" Do_Ajax_Today.success OK");

            // $('#todays_total').empty();
             $('#today').text("Resultat:"+ reply.total + " kr"  + " matchat:" + reply.totalsm + " kr" + " vinst/risk:"  + (100.0 *reply.total / reply.totalsm).toFixed(2) + " %");

          } else {
             console.log("Do_Ajax_Today.success NOT OK");
          }
      },
      error: function (request,error) {
          console.log("Do_Ajax_Today.error " + error);
      }
  });

}


function Do_Page_Reload () {
  var unique = $.now();
  $('#equity_png').attr('src', '/img/equity.png' + '?' + unique);
  $('#profit_vs_matched_42_horse_back_1_10_07_1_2_plc_1_01').attr('src', '/img/profit_vs_matched_42_horse_back_1_10_07_1_2_plc_1_01.png' + '?' + unique);
  $('#avg_price_42_horse_back_1_10_07_1_2_plc_1_01').attr('src', '/img/avg_price_42_horse_back_1_10_07_1_2_plc_1_01.png' + '?' + unique);
  $('#settled_vs_lapsed_42_horse_back_1_10_07_1_2_plc_1_01').attr('src', '/img/settled_vs_lapsed_42_horse_back_1_10_07_1_2_plc_1_01.png' + '?' + unique);
  
  $('#profit_vs_matched_42_horse_back_1_28_02_1_2_plc_1_01').attr('src', '/img/profit_vs_matched_42_horse_back_1_28_02_1_2_plc_1_01.png' + '?' + unique);
  $('#avg_price_42_horse_back_1_28_02_1_2_plc_1_01').attr('src', '/img/avg_price_42_horse_back_1_28_02_1_2_plc_1_01.png' + '?' + unique);
  $('#settled_vs_lapsed_42_horse_back_1_28_02_1_2_plc_1_01').attr('src', '/img/settled_vs_lapsed_42_horse_back_1_28_02_1_2_plc_1_01.png' + '?' + unique);

  $('#profit_vs_matched_42_horse_back_1_38_00_1_2_plc_1_01').attr('src', '/img/profit_vs_matched_42_horse_back_1_38_00_1_2_plc_1_01.png' + '?' + unique);
  $('#avg_price_42_horse_back_1_38_00_1_2_plc_1_01').attr('src', '/img/avg_price_42_horse_back_1_38_00_1_2_plc_1_01.png' + '?' + unique);
  $('#settled_vs_lapsed_42_horse_back_1_38_00_1_2_plc_1_01').attr('src', '/img/settled_vs_lapsed_42_horse_back_1_38_00_1_2_plc_1_01.png' + '?' + unique);

  $('#profit_vs_matched_42_horse_back_1_56_00_1_4_plc_1_01').attr('src', '/img/profit_vs_matched_42_horse_back_1_56_00_1_4_plc_1_01.png' + '?' + unique);
  $('#avg_price_42_horse_back_1_56_00_1_4_plc_1_01').attr('src', '/img/avg_price_42_horse_back_1_56_00_1_4_plc_1_01.png' + '?' + unique);
  $('#settled_vs_lapsed_42_horse_back_1_56_00_1_4_plc_1_01').attr('src', '/img/settled_vs_lapsed_42_horse_back_1_56_00_1_4_plc_1_01.png' + '?' + unique);
  
}

function Run_All() {
 // console.log("Run_All start");
  var pBar = document.getElementById('pb');
  Cnt = Cnt +1;

  var percent = Cnt ;
 // console.log("Run_All" + Cnt + "-" + percent );

  if (Cnt == 100) {
    console.log("Run_All start 1");
    Do_Check_Login();  
    Do_Page_Reload(); // get new graphs
    Do_Ajax_Today(); // get todays earnings
    Do_Ajax_Table('sum_todays_bets');  // and a list of bets
    Do_Ajax_Table('sum_7_days_bets');  // and a list of bets
    Do_Ajax_Table('sum_thisweeks_bets');  // and a list of bets
    Do_Ajax_Table('sum_total_bets');  // and a list of bets
    Do_Ajax_Table('starttimes');  // and a list of bets

    Cnt = 0;
    console.log("Run_All stop 1");
  } else {
    pBar.value = percent;
  }
 // console.log("Run_All stop 2");
}


function Start_Timer () {
  console.log("Start_Timer start");
  Timer = setInterval(Run_All, 1000);
  console.log("Start_Timer stop");
}


//function Do_Login() {
//
// $.ajax({url: URL,
//     data: $('#loginform').serialize(),
//     type: 'post',
//     async: 'true',
//     dataType: 'json',
//     beforeSend: function() {
//         // This callback function will trigger before data is sent
//         console.log("Do_Login.beforeSend");
//        // $.mobile.loading( "show" );
//     },
//     complete: function() {
//         // This callback function will trigger on data sent/received complete
//         console.log("Do_Login.complete");
//        // $.mobile.loading( "hide" );
//     },
//     success: function (reply) {
//         console.log("success");
//         if(reply.result == "OK") {
//            console.log("Do_Login success OK");
//            Start_Timer()
//         } else {
//            console.log("Do_Login - success NOT OK");
//         }
//     },
//     error: function (request,error) {
//         console.log("Do_Login.error " + error);
//     }
// });
//
//}


function Do_Check_Login() {
    
  console.log("Do_Check_Login start");
    
  var d = new Date();
  var n = d.getTime();
  
  //if fail server returns 401, 
  //if ok server returns 200
  $.ajax({url: URL,
      data: {'context' : "check_logged_in",
             'dummy' : n },
      type: 'get',
      async: 'false',
      dataType: 'json',
      beforeSend: function() {
          // This callback function will trigger before data is sent
          console.log("Do_Check_Login.beforeSend");
      },
      complete: function() {
          // This callback function will trigger on data sent/received complete
          console.log("Do_Check_Login.complete");
      },
      success: function (reply) {
          console.log("Do_Check_Login.success");
          login_again = false;
      },
      error: function (request,error,ex) {
          console.log("Do_Check_Login.error " + error + ex);
          login_again = true;
      }
  });

  console.log("Do_Check_Login login_again " + login_again);
  
  
  //log in if needed
  if (login_again) {
    $.ajax({url: URL,
        data: $('#loginform').serialize(),
        type: 'post',
        async: 'false',
        dataType: 'json',
        beforeSend: function() {
            // This callback function will trigger before data is sent
            console.log("Do_Login.beforeSend");
        },
        complete: function() {
            // This callback function will trigger on data sent/received complete
            console.log("Do_Login.complete");
        },
        success: function (reply) {
            console.log("success");
            if(reply.result == "OK") {
               console.log("Do_Login success OK");
            } else {
               console.log("Do_Login - success NOT OK");
            }
        },
        error: function (request,error) {
            console.log("Do_Login.error " + error);
        }
    });
  }
  console.log("Do_Check_Login stop");

}




function Do_Start() {
     //call by window.onload
     console.log("onReady Start");
     login_again = true;
     Cnt = 99;
     //start timer ...
     Start_Timer();
    // Do_Login();

     console.log("onReady Stop");
}


$(document).ready(function(){
  Do_Start();
});


