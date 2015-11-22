"use strict";
// Global variables
var dataRequest = null;
//var xmlResponse;
var dataResponse;
var lastAction = "";
var focusAfter;
var currentFunction = "";
var currentMainFunction = "";
var focusClass='focused';
/////////////////// Ajax Functions ////////////////////////////////////
// Creation of Request object

function createRequest(method, mode, action, paramArray) {
  var requestString = "?mode=" + mode + "&action="+action;
  if (paramArray) {
    for (var i = 0; i<paramArray.length; i++) {
      requestString += "&param" +i +"=" + paramArray[i];
    }
  }
  // Include the language and user in every request
  //requestString += "&lang=" + lang + "&user=" + user;
  var myRequest = $.ajax({ cache:false, url: "0",  type: method, data: requestString, 
                    async: false});

  myRequest.fail(function(jqXHR, textStatus) {  
    alert( "Request failed: " + textStatus );
    myRequest = null;
    }
  );
  //xmlResponse = myRequest.responseXML;
  dataResponse = myRequest.response;
  return myRequest;
}

function createAsyncRequest(method, mode, action, readyMethod, paramArray) {
  if (dataRequest !== null) { alert("datarequest not null after action " +lastAction); return; }
  lastAction = mode;
  hideMessage();
  if (readyMethod !== null) {
    showLoadingMessage();
  }
  var requestString = "?mode=" + mode + "&action="+action;
  if (paramArray) {
    for (var i = 0; i<paramArray.length; i++) {
      requestString += "&param" +i +"=" + paramArray[i];
    }
  }
  // Include the language, user and first start time in every request
 // requestString += "&lang=" + lang + "&user=" + user;
  dataRequest = $.ajax({ cache:false, url: "0",  type: method,  data: requestString});
  dataRequest.done(function() {
      hideLoadingMessage();
      if (readyMethod !== null) {
       // xmlResponse = dataRequest.responseXML;
        dataResponse = dataRequest.responseJSON;
       // alert(JSON.stringify(dataResponse));
        readyMethod();
      } else {
        dataRequest = null;
      }
    }
  );
  dataRequest.fail(function(jqXHR, textStatus) {  
      alert( "Request failed: " + textStatus );
      hideLoadingMessage();
      dataRequest = null;
    }
  );
}

function isActionInProgress() {
  if ($('#loading').is(":visible") || $('#message').is(":visible")) {
    return true;
  } else {
    return false;
  }
}
/////////////////// End Ajax Functions /////////////////////////////////

/////////////////// Message functions ///////////////////////////////////
function isUndefined(elem) {
  return (elem == undefined || elem === null);
}

function showLoadingMessage() {
  $('#loading').attr('class','progress');
}

function hideLoadingMessage() {
  $('#loading').attr('class','hide');
}

// Element = field that should have focus after (string or object)
// If null, show document.activeelement
function showMessage(message, element) {
  if (element) {
    if (typeof element == "string") {
      focusAfter = $('#' + element);
    } else {
      focusAfter = element;
    }
  } else {
    focusAfter = document.activeElement;
  }
  $('#message').attr('class','messageshown');
  var mess = document.getElementById(message);
  if (!isUndefined(mess)) {
    $('#msgtext').html($(mess).html());
  } else {
    $('#msgtext').html(message);
  }
  if (!iOS) {$('#closemessage').focus();}
}


function hideMessage() {
  $('#message').attr('class','hide');
}

function closeMessage() {
  $('#message').attr('class','hide');
  if ($(focusAfter).is("input[type='button']") && iOS) {
    null;
  } else {
    focusAfter.focus();
  }
}
/////////////////// End Message Functions //////////////////////////////

/////////////////// Helper functions ///////////////////////////////////
function Log(text) {
  var isDebug = true;
  if (isDebug && window.console && window.console.log) {
    console.log(text);
  }
}

function IsPosInt(data){
  return (parseInt(data)==data) && (parseInt(data) > 0);
}
function IsNonNegativeInt(data){
  return (parseInt(data)==data) && (parseInt(data) >= 0);
}

function IsFloat(data){
  return (parseFloat(data)!= "NaN");
}
function IsPosFloat(data){
  return (parseFloat(data)!= "NaN" && data > 0);
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

function disable(id) {
  if (typeof id == "string") {
    $('#'+id).css("background-color","transparent");
    $('#'+id).css("color","gray");
    $('#'+id).attr("disabled", "disabled");
  } else {
    $(id).css("background-color","transparent");
    $(id).css("color","gray");
    $(id).attr("disabled", "disabled");
  }
}

function enable(id) {
  if (typeof id == "string") {
    $('#'+id).css("background-color","");
    $('#'+id).css("color","");
    $('#'+id).removeAttr("disabled");
  } else {
    $(id).css("background-color","");
    $(id).css("color","");
    $(id).removeAttr("disabled");
  }
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

function createTextInput( value, name, maxlength, event ) {
  if (!event) {event = null;}   
  var textField = document.createElement("input");      
  textField.setAttribute("type", "text");     
  textField.setAttribute("value", value);     
  textField.setAttribute("name", name);
  if (maxlength) {
    textField.setAttribute("maxlength", maxlength); 
  }
  if (event !== null) 
  { textField.onchange = event; }
  return textField;
}

function switchTo(elementId, setFocus) {
  if (currentFunction != elementId) {
    if (currentFunction !== "") {hide(currentFunction);}
    $('#'+elementId).show();
//    $('#'+elementId).fadeIn();
//    $('#'+elementId).slideDown();
    $('#'+elementId).css("z-index", 1);
    currentFunction = elementId;
  }
  if (currentFunction == "menu") {currentMainFunction="";}
  if (setFocus) {
    var fields = $('#'+elementId).find('input:visible:enabled');
    if (iOS) {fields = $('#'+elementId).find('input[type="text"]:visible:enabled');}
    if (fields.length>0) {
      fields[0].focus();
    }
  }
}

function show(elementId) {
  $('#'+elementId).show();
//  $('#'+elementId).fadeIn();
//  $('#'+elementId).slideDown();
  $('#'+elementId).css("z-index", 1);
}


function hide(elementId) {
  $('#'+elementId).hide();
//  $('#'+elementId).fadeOut();
//  $('#'+elementId).slideUp();
  $('#'+elementId).css("z-index", -1);
}

function setOptions(selElem, valueList, optionText, optionValue) {
  var selElement = $('#' + selElem);
  if (selElement.prop) {
    var options = selElement.prop('options');
  } else {
    var options = selElement.attr('options');
  }
  $('option', selElement).remove();
  for (var i=0; i < valueList.length; i++) {
    options[options.length] = new Option(valueList[i].attributes.getNamedItem(optionText).value, valueList[i].attributes.getNamedItem(optionValue).value);
  }
}

$(function () {
  var focusedElement;
  $(document).on('focus', 'input[type=text]', function () {
    if (focusedElement == $(this)) {return;} //already focused, return so user can now place cursor at specific point in input.
    focusedElement = $(this);
    setTimeout(function () { focusedElement.select(); }, 50); //select all text in any field on focus for easy re-entry. Delay sightly to allow focus to "stick" before selecting.
  });
});


/////////////////// End Helper functions ///////////////////////////////

/////////////////// Table functions ////////////////////////////////////
function firstVisibleLine(tbl) {
  return $(tbl).find('tr:gt(0):visible:first').index();
}

function lastVisibleLine(tbl) {
  return $(tbl).find('tr:gt(0):visible:last').index();
}

function noOfVisibleLines(tbl) {
  return $(tbl).find('tr:gt(0):visible').length;
}

function firstDisplayedLine(tbl) {
  return ($(tbl).find('tr:gt(0)').filter(function ()
    { return $(this).css('display')!='none'; })).first().index(); 
}

function lastDisplayedLine(tbl) {
  return ($(tbl).find('tr:gt(0)').filter(function ()
    { return $(this).css('display')!='none'; })).last().index(); 
}

function noOfDisplayedLines(tbl) {
  return ($(tbl).find('tr:gt(0)').filter(function ()
    { return $(this).css('display')!='none'; })).length; 
}

function firstRowWithClass(tbl, className) {
  return ($(tbl.rows).filter(function ()
    { return $(this).hasClass(className); })).first().index();
}

function focusedTableLine(tbl) {
  return firstRowWithClass(tbl, focusClass);
}

function focusTableLine(lineNumber, tableName, downButton, upButton) {
  Log("focustableline");
  var tbl = document.getElementById(tableName);
  if ((tbl.rows.length <= lineNumber) || (lineNumber == focusedLine)) {
    return;
  }
  if (lineNumber == 1 || tbl.rows.length == 2) {
    Log("disable up");
    disable(upButton);
  } else {
    Log("enable up");
    enable(upButton);
  }
  var oldFocusedLine = focusedTableLine(tbl);
  Log("oldFocusedLine="+oldFocusedLine);

  if (oldFocusedLine > 0) {$(tbl.rows[oldFocusedLine]).removeClass(focusClass);}
  if ((lineNumber+1) >= tbl.rows.length || tbl.rows.length == 2) {
    Log("disable down");
    disable(downButton);
  } else {
    Log("enable up");
    enable(downButton);
  }
  var row = tbl.rows[lineNumber];
  if (focusedLine > 0) {    // moving down
    if (!$(row).is(":visible")) {
      if (focusedLine < lineNumber) {
        var j = firstDisplayedLine(tbl);
        Log("first disaplyed line="+j);
        $(tbl.rows[j]).css('display','none');
      } else {              // moving up
        var j = lastDisplayedLine(tbl);
        Log("last disaplyed line="+j);
        $(tbl.rows[j]).css('display','none');
      }
      $(row).css('display', '');
    }
  }
  $(row).addClass(focusClass); 
  focusedLine = lineNumber;
  var fields = $(tbl.rows[focusedLine]).find('input:visible:enabled');
  if (fields.length>0) {
    fields[0].focus();
  }
  Log("focused line is now="+focusedLine);
}

function moveTableDown(tableName, downButton, upButton) {
  focusedLine = focusedTableLine(document.getElementById(tableName));
  var newRow = focusedLine+1;
  focusTableLine(newRow, tableName, downButton, upButton); 
}

function moveTableUp(tableName, downButton, upButton) {
  focusedLine = focusedTableLine(document.getElementById(tableName));
  var newRow = focusedLine-1;
  focusTableLine(newRow, tableName, downButton, upButton); 
}


//bnl
$.makeTable = function (mydata) {
    var table = $('<table border=1>');
    var tblHeader = "<tr>";
    for (var k in mydata[0]) tblHeader += "<th>" + k + "</th>";
    tblHeader += "</tr>";
    $(tblHeader).appendTo(table);
    $.each(mydata, function (index, value) {
        var TableRow = "<tr>";
        $.each(value, function (key, val) {
            TableRow += "<td>" + val + "</td>";
        });
        TableRow += "</tr>";
        $(table).append(TableRow);
    });
    return ($(table));
};

/////////////////// End Table functions ///////////////////////////////


$.makeParagraph = function (mydata) {
  var para = "<p>" + mydata + "</p>"
  return ($(para));
};
