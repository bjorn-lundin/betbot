// Global variables
var focusedLine = -1;
var user = "";
var lang="";
var startTitle = document.title;
var isLoggedIn = false;

var iOS = false;

/////////////////// Here we start //// /////////////////////////////////

$(document).ready(function(){
  iOS = ( navigator.userAgent.match(/(iPad|iPhone|iPod)/g) ? true : false );
  startLogin();
});

function startLogin() {

  
  hideMessage();
  $('#host1').html(location.hostname);
  $('#host2').html(location.hostname);
  $( "div.mainform" ).hide();
  $( "div.mainform" ).css( "z-index", -1);
  $('#loginForm')[0].reset(); 
  
  if ( ! isLoggedIn) {
    switchTo("login", true);
  } else {
    switchTo("menu", true);
  }  
  
}


function isUndefined(elem) {
  return (elem == undefined || elem === null);
}

function setDisabled(el, val) {   
  if (el === null) {return;}
  try { 
    el.disabled = val;
  } catch(E){}
  if (el.childNodes && el.childNodes.length > 0) {
    for (var x = 0; x < el.childNodes.length; x++) { 
            setDisabled(el.childNodes[x], val);                    
    } 
  }            
}

function disableButton(id) {
  $('#'+id).attr("disabled", "disabled");
}

function enableButton(id) {
  $('#'+id).removeAttr("disabled");
}

function createButton( value, name, event) {
  if (!event) {event = null;}   
  var button = document.createElement("input");      
  button.setAttribute("type", "button");     
  button.setAttribute("value", value);     
  button.setAttribute("name", name);
  if (event !== null)
  {  button.onclick = event; }
  return button;
}

function createTextInput( value, name, event ) {
  if (!event) {event = null;}   
  var textField = document.createElement("input");      
  textField.setAttribute("type", "text");     
  textField.setAttribute("value", value);     
  textField.setAttribute("name", name);
  if (event !== null) 
  { textField.onchange = event; }
  return textField;
}


function Login() {
  var params = []; 
  
 if ($('#selUserbnl').is(':checked')) { 
   user="bnl";
 };  
  
 if ($('#selUserjmb').is(':checked')) { 
   user="jmb";
 };  
 if ($('#selUsermsm').is(':checked')) { 
   user="msm";
 };  
  
  if (user == "") {
    return;
  }
  params[0] = user;
  createAsyncRequest("GET", "login", "IN", loginAnswer, params);
  return false;
}


function loginAnswer() {
  var JSONresult = dataResponse;
  
  dataRequest = null;
  if (JSONresult.result != "OK") {   // Not authorized
    $('#txtPassword').val('');
    showMessage("Not authorized" + JSONresult.text, "txtPassword");
    return false;
  }
  isLoggedIn = true;
  document.title = startTitle + " " + user;
  switchTo('menu', true);
  return true;
}

//function Logout() {
//  var xmlhttp = createRequest("GET", "logout", "OUT");
//  $('#txtPassword').val('');
//  if (localStorage.getItem("stylesheet")) {
//    $("#selStylesheet").val(localStorage.getItem("stylesheet"));
//  }
//  isLoggedIn = false;
//  switchTo('login', true);
//}



function doReportToday () {
  var params = []; 
  createAsyncRequest("GET", "todays_bets", "IN", doReportTodayAnswer, params);
  return false;
}


function doReportTodayAnswer () {
  var JSONresult = dataResponse;
  dataRequest = null;
  if (JSONresult.result != "OK") {   // Not authorized
    $('#txtPassword').val('');
    showMessage("bad response" + JSONresult.text, "txtPassword");
    return false;
  }

  //clear from old results
  $('#reportTodaysBetTable').empty();
  $('#reportTodaysBetTotal').empty();
  
  //fill the table
  var table = $.makeTable(JSONresult.datatable);  
  $(table).appendTo("#reportTodaysBetTable");  

  var para = $.makeParagraph("Totalt idag: " + JSONresult.total)
  $(para).appendTo("#reportTodaysBetTotal");  
  
  show('reportTodaysBetTotal', true);
  show('reportTodaysBetTable', true);
  switchTo('reportTodaysBetPage', true);
  return true;
}



function doReportYesterday () {
  var params = []; 
  createAsyncRequest("GET", "yesterdays_bets", "IN", doReportYesterdayAnswer, params);
  return false;
}

function doReportYesterdayAnswer () {
  var JSONresult = dataResponse;
  dataRequest = null;
  if (JSONresult.result != "OK") {   // Not authorized
    $('#txtPassword').val('');
    showMessage("bad response" + JSONresult.text, "txtPassword");
    return false;
  }
  //clear from old results
  $('#reportYesterdaysBetTable').empty();
  $('#reportYesterdaysBetTotal').empty();

  //fill the table
  var table = $.makeTable(JSONresult.datatable);
  $(table).appendTo("#reportYesterdaysBetTable");  

  var para = $.makeParagraph("Totalt igår: " + JSONresult.total)
  $(para).appendTo("#reportYesterdaysBetTotal");  
  
  show('reportYesterdaysBetTotal', true);
  show('reportYesterdaysBetTable', true);
  switchTo('reportYesterdaysBetPage', true);
  return true;
}


function doReportThisWeek () {
  var params = []; 
  createAsyncRequest("GET", "thisweeks_bets", "IN", doReportThisWeekAnswer, params);
  return false;
}

function doReportThisWeekAnswer () {
  var JSONresult = dataResponse;
  dataRequest = null;
  if (JSONresult.result != "OK") {   // Not authorized
    $('#txtPassword').val('');
    showMessage("bad response" + JSONresult.text, "txtPassword");
    return false;
  }

  //clear from old results
  $('#reportThisWeeksBetTable').empty();
  $('#reportThisWeeksBetTotal').empty();
  
  //fill the table
  var table = $.makeTable(JSONresult.datatable);
  $(table).appendTo("#reportThisWeeksBetTable");  

  var para = $.makeParagraph("Totalt denna vecka: " + JSONresult.total)
  $(para).appendTo("#reportThisWeeksBetTotal");  
  
  show('reportThisWeeksBetTotal', true);
  show('reportThisWeeksBetTable', true);
  switchTo('reportThisWeeksBetPage', true);
  return true;
}






















