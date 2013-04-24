

    
    
    var ws = new Object;
    var ws_trace = new Object;
    var history = new Array();
    var index = 0;
    var HOST = "new.deepmemo.com";
    var wait_answer = 0 ;
    var realtimeLoader;
    var editor;
    var picker;
    var LOADED = 0;
    var CookieName = "ide_doc_path";  
    var CURRENT_DOCUMENT = "";
    var PARENT_DIRECTORY="";
    var WHOST = "ws://" + HOST+"/websocket/";
    
    function onFileLoaded(doc) {
      var string = doc.getModel().getRoot().get('text');
      string +="\n";      
      editor.setValue(string);
    }
   function hide(Id){
     
	$("#"+Id).hide("fast");
     
   }
   function show(Id){
     
	$("#"+Id).show("fast");
     
   }
   function createCookie(name, value, days) {
    if (days) {
        var date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        var expires = "; expires=" + date.toGMTString();
    } else var expires = "";
    document.cookie = escape(name) + "=" + escape(value) + expires + "; path=/";
}

    function readCookie(name) {
	var nameEQ = escape(name) + "=";
	var ca = document.cookie.split(';');
	for (var i = 0; i < ca.length; i++) {
	    var c = ca[i];
	    while (c.charAt(0) == ' ') c = c.substring(1, c.length);
	    if (c.indexOf(nameEQ) == 0) return unescape(c.substring(nameEQ.length, c.length));
	}
	return null;
    }

    function eraseCookie(name) {
	createCookie(name, "", -1);
    }
    
    function create_new_project(){
		
	  var picker_creater = function(resp){
	      PARENT_DIRECTORY = resp.id;
	      insert_file("calculate_8_queens", resp.id);
	      insert_file("calculate_any_queens",resp.id);
	      insert_file("simple_recursion", resp.id);
	      insert_file("simple_operation", resp.id);
	      createCookie(CookieName, PARENT_DIRECTORY);
	      hide("create_new_project");
	      show("online_ide_button");
	  };
	  
	  realtimeLoader.new_project( picker_creater );     
	 
      
    }    
    function initializeModel(model){
    
	  return;
    }
    function my_after_auth(){
	  $("#authorizeButton").hide("fast");
	  open_console();
    } 
   
    function listen(obj, E){
	  if(E.keyCode == 13 ){
		Code = $.trim(obj.value);
		if(wait_answer){
			if(Code != "yes." && Code != "no."){
				$("<p>| -? Enter yes. or no. </p>").insertBefore("#sse");
				scroll_console();
				return;			
			}
		}
		
		if( Code.charAt(Code.length - 1) == "." ){
		
			  var Var  = "<p>| -? " + obj.value+"</p>";
			  
			  var Var1 = obj.value;
			  Var1 = Var1.replace("\n","");
			  Var1 = Var1 + " ";
			  obj.value ="";
			  $("<p>| -? " + Var +"</p>").insertBefore("#sse");
			  scroll_console();
			  wait_answer = 0;
			  history[$.trim(Var1)] = 1 ;
			  index = 0;
			  send(Var1);
			  
     	  	          $("#code").prop("disabled", true);     

		}
	  
	  }
	   if(E.keyCode == 38 ){//up
		  if(index == 0)
			return ;
		
		  if(index == 1){
		  
			document.getElementById("code").value = "";
			index = 0;
			return ;
		  }
		  
		  var i = 0;
		  for(key in history){
			  if(i+1 == index){
			   
			  	document.getElementById("code").value = key;

// 				$("#code").attr( { "value": key } );
				index = i;
				return ;

			  }
			  i++;
		  }
		  
	
	  }
	  if(E.keyCode == 40 ){//down
	  
		 var i = 1;
		 
		 for(key in history){
			  if(i-1 ==  index){
			  	document.getElementById("code").value = key;
// 				$("#code").attr(  "value", key  );
				index = i;
				return ;
			  }
			  i++;
			  
		  }
	  
	  
	  
	  }
	  
	  
    }
     function scroll_console(){
	 $("#msgs").animate({
			      scrollTop: $("#msgs").get(0).scrollHeight
			    }, 1500);
	  
    
    }
    function scroll_trace(){
	 $("#trace_msg").animate({
			      scrollTop: $("#trace_msg").get(0).scrollHeight
			    }, 1500);
	  
    
    }
    
    function listen_trace(obj, E){
	  if(E.keyCode == 13 ){
		    Code = $.trim(obj.value);
		    if( Code == "yes." ){
			      var Var  = "<p>| -? " + obj.value+"</p>";
			      
			      var Var1 = obj.value;
			      Var1 = Var1.replace("\n","");
			      Var1 = Var1 + " ";
			      obj.value ="";
   		      	       $("<p>| -? " + Var1 +"</p>").insertBefore("#trace_sse");	    
			      scroll_trace();
			      send_trace(Var1);
       	  	              $("#trace_input").prop("disabled", true);
			      return  ;
		    }
		    if( Code == "no." ){
		          var Var  = "<p>| -? " + obj.value+"</p>";
			  var Var1 = obj.value;
			  Var1 = Var1.replace("\n","");
			  Var1 = Var1 + " ";
			  obj.value ="";
			  
			  $("<p>| -? " + Var1 +"</p>").insertBefore("#trace_sse");
			   send_trace(Var1);
			   scroll_trace();
   	  	          $("#trace_input").prop("disabled", true);

			  return  ; 
		    }
		
		    alert("Enter yes or no please");
			
			  
		}
	  
	  
    }
   
    function  reloadall_code(){
		    var new_function = function(Data){
			  $("<p>| -? " + Data +"</p>").insertBefore("#sse");
			  scroll_console();
			  
		    }
		    var  params = { code: editor.getValue()  };
	            $.ajax({
                        type: "POST",
                        url: "http://" + HOST +"/command/reload" ,
                        data: params,
                        success: new_function
                        
                        }
                      );
    
    
    }
    function show_trace(){
	  $("#trace").slideDown("slow");
    
    
    }
    function close_editor(){
    
	  
    
	 $("#container_editor").hide("fast");
    
    }
    function clear_console(){
	$("#msgs").html("");
	clear_trace();
	
    
    }
      function close_console1(){
      
	$("#console").hide("fast");
	close_trace();
    
    }
    function close_trace(){
	    
	      
	  $("#trace").hide("fast");
    }
    function clear_trace(){

	  $("#trace_msg").html("");
    }
    function show_online(){
    
	    close_help();
	    close_console1();
	    
	    if(LOADED == 0){
		var new_function=function(Data){
		      editor.setValue(Data);
		      LOADED=1;
		};
	      
		$.ajax({
			    type: "GET",
			    contentType: 'text/plain',
			    url: "http://" + HOST +"/command/plain_code" ,
			    success: new_function,
			    }
		);
	    }
	    $("#container_editor").slideDown("slow");
    
    
    }
    function export_code(){
		alert("not implemented");
    
    }
    
    function load_code(){
		    var new_function = function(Data){
// 			  $("<p>| -? " + Data +"</p>").appendTo("#msgs");
			  alert("Code loaded");
			  
		    }
		    Code = editor.getValue(),
		    //hack for numbers
		    Code = Code.replace(/(\d+)\.(\d+)/mg,"$1#%#$2");
		    Code = Code.replace(/%.+\n/mg,"");
   		    Code = $.trim(Code);

		    var  params = { code: Code   };
	            $.ajax({
                        type: "POST",
                        url: "http://" + HOST +"/command/upload_code" ,
                        data: params,
                        success: new_function
                        
                        }
                      );
    
    }
    function send_trace(Code){
	ws_trace.send(Code);
	console.log('Message sent to trace');
    }
    function send(Code)
    {
    
	send_trace("next");/* at first time*/
	ws.send(Code);
	console.log('Message sent');
    }
    function help(){
	close_console1();
	close_editor();
	$("#container_help").show("fast");
    
    }
    function close_help(){
	  $("#container_help").hide("fast");
    }
    function close_console(){
	 	  document.getElementById("container").innerHTML="Good bye";
		  ws.close();
    
    }
    function choose_drive(){
	if(!picker)
	  createPicker();
// 	    google.setOnLoadCallback(createPicker);
	
	
	picker.setVisible(true);
    
    
    }
    var CLIENT_ID = '768399903870.apps.googleusercontent.com';
    var SCOPES = 'https://www.googleapis.com/auth/drive';

      /**
       * Called when the client library is loaded to start the auth flow.
       */
   
      /**
       * Check if the current user has authorized the application.
       */
 
      /**
       * Called when authorization server replies.
       *
       * @param {Object} authResult Authorization result.
       */

      function createPicker() {
	  var view = new google.picker.View(google.picker.ViewId.DOCS);
	  if(PARENT_DIRECTORY)
		view.setParent(PARENT_DIRECTORY);
//       view.setMimeTypes("txt/plain");    
// 	  var access_token = gapi.auth.getToken("token",null);
	  picker = new google.picker.PickerBuilder()
	     
//           .enableFeature(google.picker.Feature.NAV_HIDDEN)
//           .enableFeature(google.picker.Feature.MULTISELECT_ENABLED)
          .setAppId('768399903870')
// 	  .setOAuthToken(access_token) //Optional: The auth token used in the current Drive API session.
          .addView(view)
          .addView(new google.picker.DocsUploadView())
          .setCallback(pickerCallback)
          .build();
       
    }
    function  update_editor(string){
	    editor.setValue(string);
    
    }
    // A simple callback implementation.
    function pickerCallback(data) {
      if (data.action == google.picker.Action.PICKED) {
	  var fileId = data.docs[0].id;
	  CURRENT_DOCUMENT = fileId;
          realtimeLoader.get_file(fileId, update_editor);
      }
    }
    function save_file(){
      
       
	alert("not implementer");
	
    }
    
    
    function open_console()
    {
	if (!("WebSocket" in window)) {
	    alert("This browser does not support WebSockets");
	    return;
	}
	close_editor();
	close_help();
	$("#console").slideDown("slow");
	$("#code").prop("disabled", false);
	$("#code").focus();
	show_trace();
// // 	document.getElementById("code").value='';
// 	$("#code").focus();
	

	/* @todo: Change to your own server IP address */
	
    } 

