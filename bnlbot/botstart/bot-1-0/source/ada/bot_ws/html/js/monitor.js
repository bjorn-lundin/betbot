
var Timer;
var Cnt;
//var URL="http://192.168.1.229:9080"
//var URL ="https://lundin.duckdns.org"
var URL="http://lundin.duckdns.org"
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
           // console.log("key: " + key + " val: " + val);
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
      async: true,
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

function Do_Ajax_Today() {
  var d = new Date();
  var n = d.getTime();

  $.ajax({url: URL,
      data: {'context' : "todays_total",
             'dummy' : n },
      type: 'get',
      async: true,
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

             if (reply.totalsm == 0.0) {
               $('#today').text("Resultat:"+ reply.total + " kr"  + " matchat:" + reply.totalsm + " kr" + " vinst/risk: -");
             } else {
            // $('#todays_total').empty();
               $('#today').text("Resultat:"+ reply.total + " kr"  + " matchat:" + reply.totalsm + " kr" + " vinst/risk:"  + (100.0 *reply.total / reply.totalsm).toFixed(2) + " %");
             }
          } else {
             console.log("Do_Ajax_Today.success NOT OK");
          }
      },
      error: function (request,error) {
          console.log("Do_Ajax_Today.error " + error);
      }
  });

}


function Do_Page_Reload (user) {
  var unique = $.now();

  types = ["profit_vs_matched", "avg_price", "settled_vs_lapsed"];
  days  = ["_42"];
  odds = ["_horse_back_1_10_07_1_2_plc_1_01", "_horse_back_1_28_02_1_2_plc_1_01", "_horse_back_1_38_00_1_2_plc_1_01", "_horse_back_1_56_00_1_4_plc_1_01"];
  markettypes = ["", "_chs"];
  typesLen = types.length;
  daysLen = days.length;
  oddsLen = odds.length;
  markettypesLen = markettypes.length;

  $('#equity_png').attr('src', '/' + user + '/equity.png' + '?' + unique);

  // Get the <div> element with id forty_two_days"
  var d = document.getElementById("forty_two_days");

  // As long as <d> has a child node, remove it
  while (d.hasChildNodes()) {
    d.removeChild(d.firstChild);
  }

  //  $('#profit_vs_matched_42_horse_back_1_10_07_1_2_plc_1_01').attr('src', '/img/profit_vs_matched_42_horse_back_1_10_07_1_2_plc_1_01.png' + '?' + unique);
  for (m = 0; m < markettypesLen; m++) {
    var h2 = document.createElement("h2");
    if (markettypes[m] == "" ) {
      h2.innerText ="Hcap, Non-Chase, Non-Hurdles races";
    } else if  (markettypes[m] == "_chs" ) {
      h2.innerText ="Hcap, Chase, Non-Hurdles races";
    }
    $('#forty_two_days').append(h2);


    for (t = 0 ; t < typesLen; t++) {
      for (d = 0; d < daysLen; d++) {
        for (o = 0; o < oddsLen; o++) {

          var id=types[t] + days[d] + odds[o] + markettypes[m];
          var src= '/' + user + '/' + id + '.png';
          var u='?' + unique;

          var div = document.createElement("DIV");
          var h3 = document.createElement("h3");
          h3.innerText = id;
          div.append(h3);

          var image = document.createElement("IMG");
          image.alt = id;
          image.setAttribute('class', 'photo');
          image.src = src;

          div.append(image);

          var hr = document.createElement("hr");
          div.append(hr);

          $('#forty_two_days').append(div);
        }
      }
    }
  }
}

////////////////////////

function Run_All () {
 // console.log("Run_All start");
  var pBar = document.getElementById('pb');
  Cnt = Cnt +1;

  var percent = Cnt ;
 // console.log("Run_All" + Cnt + "-" + percent );

  if (Cnt == 100) {
    var user = document.getElementById('username').value 
    console.log("Run_All start 1 '" + user + "'");
    keep_going = Do_Check_Login(user);
    if (keep_going) {
      Do_Page_Reload(user); // get new graphs
      Do_Ajax_Today(); // get todays earnings
      Do_Ajax_Table('sum_todays_bets');  // and a list of bets
      Do_Ajax_Table('sum_7_days_bets');  // and a list of bets
      Do_Ajax_Table('sum_thisweeks_bets');  // and a list of bets
      Do_Ajax_Table('sum_total_bets');  // and a list of bets
      Do_Ajax_Table('starttimes');  // and a list of bets
    }
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
  console.log("Start_Timer stop ");
}

/////////////////////////////



function Do_Check_Login(user) {
  console.log("Do_Check_Login start");
  login_again = true;
  res=false;
  var d = new Date();
  var n = d.getTime();

  //if fail server returns 401,
  //if ok server returns 200
  $.ajax({url: URL,
      data: {'context' : "check_logged_in",
             'username' : user,
             'dummy' : n },
      type: 'get',
      async: false,
      dataType: 'json',
      beforeSend: function() {
          // This callback function will trigger before data is sent
          console.log("Do_Check_Login-1.beforeSend");
      },
      complete: function() {
          // This callback function will trigger on data sent/received complete
          console.log("Do_Check_Login-1.complete");
      },
      success: function (reply) {
          console.log("Do_Check_Login-1.success");
          login_again = false;
          res = true;
      },
      error: function (request,error) {
          console.log("Do_Check_Login-1.error " + error);
      }
  });

  console.log("Do_Check_Login login_again " + login_again);


  //log in if needed
  if (login_again) {
    $.ajax({url: URL,
        data: $('#loginform').serialize(),
        type: 'post',
        async: false,
        dataType: 'json',
        beforeSend: function() {
            // This callback function will trigger before data is sent
            console.log("Do_Login-2.beforeSend");
        },
        complete: function() {
            // This callback function will trigger on data sent/received complete
            console.log("Do_Login-2.complete");
        },
        success: function (reply) {
            console.log("Do_login-2.success");
            if(reply.result == "OK") {
               console.log("Do_Login-2 success OK");
               res = true;
            } else {
               console.log("Do_Login-2 - success NOT OK");
            }
        },
        error: function (request,error) {
            console.log("Do_Login-2.error " + error);
        }
    });
  }
  console.log("Do_Check_Login stop - return -> " + res);
  return res;
}

/////////////////////////////

function Do_Start() {
     //call by window.onload
     console.log("onReady Start");
     login_again = true;
     Cnt = 96;
     //start timer ...
     Start_Timer();
    // Do_Login();
     console.log("onReady Stop");
}


$(document).ready(function(){
  Do_Start();
});


