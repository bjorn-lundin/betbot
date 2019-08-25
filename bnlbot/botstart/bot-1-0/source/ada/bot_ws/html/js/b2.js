  //track changes in radiobtn clicks
var selectedRadio ='bnl';
var context = 'todays_bets'

//bnl
$.makeTable = function (mydata) {
    var table = $('<table data-role="table" class="ui-responsive" id="datatable">');
    var tblHeader = "<thead><tr>";
    for (var k in mydata[0]) tblHeader += "<th>" + k + "</th>";
    tblHeader += "</tr></thead><tbody>";
    $(tblHeader).appendTo(table);
    $.each(mydata, function (index, value) {
        var TableRow = "<tr>";
        $.each(value, function (key, val) {
           // console.log("key: " + key + " val: " + val);
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
    $(table).append('</tbody></table>');
    return ($(table));
};

function Do_Login() { // catch the form's submit event
      // Send data to server through the Ajax call
      // action is functionality we want to call and outputJSON is our data
         
      var params = $('#loginform').serialize();
      console.log("Do_Login: params" + params + "'");
      var xhr = new XMLHttpRequest();
      //xhr.open('POST', URL + '/login', false); //synchronous
      xhr.open('POST', '/login', false); //synchronous
      xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
      xhr.send(params); 
      var reply = JSON.parse(xhr.responseText);
      console.log('Do_Login got:' + reply);
      if (reply.result == "OK") {
         console.log("Do_Login success OK");
         $.mobile.changePage("#menu");
      } else {
         console.log("Do_Login success NOT OK");
      }      
}


$(document).ready(function(){
     $('#loginform input').on('change', function() {
         selectedRadio = $('input[name="username"]:checked', '#loginform').val();
         console.log("selectedRadio " + selectedRadio);
     });

//  $( document ).ajaxError(function() {
//    $('#viewer_content').empty();
//    $('#total').text("Triggered ajaxError handler."  );
//  });


  $(document).on('click', '#submit', function() { // catch the form's submit event
      // Send data to server through the Ajax call
      // action is functionality we want to call and outputJSON is our data
      Do_Login();
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

  $('#thismonth').on('tap', function() {
      context ='thismonths_bets';
      console.log("thismonth - context " + context);
  });

  $('#lastmonth').on('tap', function() {
      context ='lastmonths_bets';
      console.log("lastmonth - context " + context);
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
              console.log("success pageshow");
              if(reply.result == "OK") {
                 console.log("success pageshow OK");

                 $('#viewer_content').empty();
                 $('#total').text("Resultat:"+ reply.total + " kr" );

                 //fill the table
                 var table = $.makeTable(reply.datatable);
                 $('#viewer_content').html(table).trigger('create')


              } else {
                 console.log("success pageshow NOT OK");
              }
          },
          error: function (request,error) {
              console.log("error pageshow " + error);
          }
    });

  });

});

