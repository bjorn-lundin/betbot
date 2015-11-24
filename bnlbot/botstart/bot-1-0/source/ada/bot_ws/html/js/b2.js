  //track changes in radiobtn clicks
var selectedRadio ='bnl'; 
$(document).ready(function(){
     $('#loginform input').on('change', function() {
         selectedRadio = $('input[name="username"]:checked', '#loginform').val();
         console.log("selectedRadio " + selectedRadio);
     });
});  
$(document).on('pageinit', '#login', function(){  
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
                        success: function (result) {
                            console.log("success");
                            if(result.result == "OK") {
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
});    