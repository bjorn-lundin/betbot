
// Global variables
var mode = "";

if (!window.Node) {
  var Node = {
    ELEMENT_NODE: 1,
    ATTRIBUTE_NODE: 2,
    TEXT_NODE: 3,
    COMMENT_NODE :8,
    DOCUMENT_NODE: 9,
    DOCUMENT_FRAGMENT_NODE:11
  };
}

/////////////////// Ajax Functions ////////////////////////////////////
// Creation of Request object
function createXMLHttp() {
  if (typeof XMLHttpRequest != 'undefined') {  
    return new XMLHttpRequest(); 
  } else {
    throw new Error('XMLHttp (AJAX) not supported');
  }
}

function createRequest(requestString) {
  var xmlhttp = createXMLHttp();
  xmlhttp.open("POST", requestString, false);
  xmlhttp.send(null);
  xmlhttp = null;
}
/////////////////// End Ajax Functions /////////////////////////////////

//called by body.onLoad, ie when doc is fully loaded
function setup() {	
 // Clear all forms - this may be a refresh
  for (var i=0; i<document.forms.length; i++) {
    clearFormData(document.forms[i]);
  } 
}

function clearFormData(formName) {
  var form = formName;
  if (typeof formName == 'string') {
    form = document.getElementById(formName);
  }
  for (i=0; i<form.elements.length; i++)  {
    if (form.elements[i].type == "text") {
      form.elements[i].value="";
    } else if (form.elements[i].type == 'textarea') {
      form.elements[i].value="";
    } else if (form.elements[i].type == 'checkbox') {
      form.elements[i].checked = false;
    }
  }
}

function Trim(text) {
  return text.replace(/^\s+|\s+$/g, '') ;
}

function Associate(unk_id,sugg_id) {
  var requestString = "?action=update&unk_id="+unk_id+"&sugg_id="+sugg_id;
  alert("start Associate" + unk_id + " + " + sugg_id + " '" + requestString + "'");
  createRequest(requestString)  ;
  alert("done Associate" + unk_id + " + " + sugg_id + " '" + requestString + "'");
}
