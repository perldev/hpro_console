

    
    
    var ws = new Object;
    var ws_trace = new Object;
    var history = new Array();
    var index = 0;
    var HOST = "new.deepmemo.com";
    var wait_answer = 0 ;
    var realtimeLoader;
    var editor;
    var picker;
    var LOADED = 1;
    var CookieName = "ide_doc_path_prolog";  
    var CURRENT_DOCUMENT = "";
    var CURRENT_NAME = "";
    var PARENT_DIRECTORY="";
    var SUB_DIRECTORY_NAME = "";
    var SUB_DIRECTORY="";
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
	      insert_file("queens_8", SampleCode["queens_8"] ,resp.id, 0);
	      insert_file("any_queens", SampleCode["any_queens"] , resp.id, 0);
	      insert_file("simple_recursion", SampleCode["simple_recursion"] ,resp.id, 0);
	      insert_file("simple_operation", SampleCode["simple_operation"] , resp.id, 0);
	      SUB_DIRECTORY = resp.id;
	      SUB_DIRECTORY_NAME = "PrologSamples";
	      setTimeout(function(){ fill_project_list(SUB_DIRECTORY) },3000);
	      CURRENT_DOCUMENT = "";
	      update_empty_titles(SUB_DIRECTORY_NAME);
	      editor.setValue("");
	      alert("We create a sample  project PrologSamples  in your GoogleDrive ");
	      
// 	      hide("create_new_project");
// 	      show("online_ide_button");
	  };
	  
	  realtimeLoader.new_project( picker_creater, "PrologSamples", PARENT_DIRECTORY );     
	 
      
    }    
    function initializeModel(model){
    
	  return;
    }
    function my_after_auth(){
	  $("#authorizeButton").hide("fast");
	  show_online();
	  var Path = readCookie(CookieName);
	  
	  if(Path||Path==""){
	    PARENT_DIRECTORY = Path;
	   
// 	    show("online_ide_button");
// 	    hide("create_new_project");
	  }else{  
	     create_working_dir();	     
	        
	  }  
    } 
    function create_working_dir(){
    	 
      
	if(confirm("Could i create a working folder on your google drive?") ){
	      var access_token = gapi.auth.getToken("token",null);
	      
	      var callback = function(resp){
		PARENT_DIRECTORY = resp.id;
		createCookie(CookieName, PARENT_DIRECTORY);
		if(confirm("Do you want create sample project") ){
		    create_new_project();
		    
		}	
		
	      };
	      
	      var request = gapi.client.request({
		  'path': '/drive/v2/files/',
		  'method': 'POST',
		  'headers': {
		      'Content-Type': 'application/json',
		      'Authorization': 'Bearer ' + access_token.access_token,             
		  },
		  
		  'body':{
		      "title" : "PrologWorkSpace",
		      "mimeType" : "application/vnd.google-apps.folder",
		  }
	      });
	      request.execute( callback  );
	    
	}else{
	  createCookie(CookieName, "");
	  
	  
	}
    
      
		      
    }
    function update_empty_titles(Name){
      
      $("#project_title").html("<h6>" + Name+" &gt; new untitled file </h6>");
      
    }
    
    function create_new_project_common(){
	   
	    var Name = prompt("Please enter project's name","ProjectName");
	    if (Name==null || Name=="")
	    {
		alert("The name of project can't be empty");
		return;
		
	    } 	    
            var callback = function(resp){
		alert("The project "+ Name + " was created successfully");	      
		editor.setValue("");
		CURRENT_DOCUMENT = "";
		SUB_DIRECTORY = resp.id;
		SUB_DIRECTORY_NAME = Name;
		update_empty_titles(SUB_DIRECTORY_NAME);
		Str = "<h5> Project's files: </h5>";
		$("#project_files").html(Str);

		
	    };
	    
	    realtimeLoader.new_project(callback, Name, PARENT_DIRECTORY );     

     
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
			  open_console();
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
// 	  var view = new google.picker.View(google.picker.ViewId.DOCS);
	  var view_d = new google.picker.View(google.picker.ViewId.FOLDERS);
	  var upload_v = new google.picker.DocsUploadView();
	  upload_v.setIncludeFolders(true);
	  
 	  if(PARENT_DIRECTORY && PARENT_DIRECTORY != "")
//  		view.setParent(PARENT_DIRECTORY);
		view_d.setParent(PARENT_DIRECTORY);  
//       view.setMimeTypes("txt/plain");    
// 	  var access_token = gapi.auth.getToken("token",null);
// 	  view.setIncludeFolders(true);
	  picker = new google.picker.PickerBuilder()
	     
//           .enableFeature(google.picker.Feature.NAV_HIDDEN)
//           .enableFeature(google.picker.Feature.MULTISELECT_ENABLED)
          .setAppId('768399903870')
// 	  .setOAuthToken(access_token) //Optional: The auth token used in the current Drive API session.
//           .addView(view)
	  .addView(view_d)
          .addView(upload_v)
          .setCallback(pickerCallback)
          .build();
       
    }
    function  update_editor(string, meta){
	  editor.setValue(string);	    
	  CURRENT_NAME = meta.title;
  	  SUB_DIRECTORY =  meta.parents[0].id;
	  update_title();
	  fill_project_list(SUB_DIRECTORY);
    
    }
    function update_name_title(name){
    	    $("#project_title").html("<h6>" + SUB_DIRECTORY_NAME +" &gt; " + name + "</h6>");

      
    }
    function update_title(){
	  
      var request = gapi.client.request({
	  'fileId': SUB_DIRECTORY,
	   method: 'GET',
	   path: "/drive/v2/files/"+SUB_DIRECTORY
	});
	request.execute(function(resp) {
	    SUB_DIRECTORY_NAME= resp.title;
	    $("#project_title").html("<h6>" + SUB_DIRECTORY_NAME+" &gt; " + CURRENT_NAME + "</h6>");

	});

    } 
    // A simple callback implementation.
    function pickerCallback(data) {
      if (data.action == google.picker.Action.PICKED) {
	  var fileId = data.docs[0].id;
	  
	  CURRENT_DOCUMENT = fileId;
          realtimeLoader.get_file(fileId, update_editor);
      }
    }
    function retrieveAllFiles(callback, Dir) {
      
      
	var retrievePageOfFiles = function(request, result) {
	  request.execute(function(resp) {
	    result = result.concat(resp.items);
	    var nextPageToken = resp.nextPageToken;
	    if (nextPageToken) {
	      request = gapi.client.drive.files.list({
		'pageToken': nextPageToken,
		"q": "'"+ Dir +"' in parents "
	      });
	      retrievePageOfFiles(request, result);
	    } else {
	      callback(result);
	    }
	  });
	}
	var initialRequest = gapi.client.drive.files.list({"q": "'"+ Dir +"' in parents "});
	
	retrievePageOfFiles(initialRequest, []);
	
    }
    function open_file(FileId){
      realtimeLoader.get_file(FileId, update_editor);
      CURRENT_DOCUMENT = FileId;
      
    }
    
    function process(Result){
      
      Str = "<h5> Project's files: </h5>";
      for(item in Result){
	    Str += "<a class=\"btn\" href=\"javascript:open_file('"+Result[item].id+"')\">"+ Result[item].title +" </a>";
      }
      $("#project_files").html(Str);
    }
    function fill_project_list(Dir){
      
        gapi.client.load('drive', 'v2', function() {
	    retrieveAllFiles(process, Dir);
	});
      
      
      
      
    }
    function save_file(Code){
	  gd_updateFile(CURRENT_DOCUMENT, SUB_DIRECTORY, Code, 0 );
      
    }
    function new_file(){
      
    
	  if(SUB_DIRECTORY==""){
		alert("Create project  at first");
		return;
	    
	    
	  }
	   var  text = editor.getValue();
	   if(CURRENT_DOCUMENT !=""){
		if(confirm("Do you want to save current file")){
		      save_file( editor.getValue() );		  
		}
	     
	   }
	   if(text!=""&&CURRENT_DOCUMENT==""){
	     if(confirm("Do you want to save current file")){
		var name = prompt("Please enter the filename","");
		if (name!=null && name!=""){	
		  
		  insert_file(name, text, SUB_DIRECTORY, 0 ); 
		  setTimeout(function(){ fill_project_list(SUB_DIRECTORY) },5000);	       
	        }
	     
	    }else{
		   alert("The filename can't be empty");
		   return;
	      
	    }
	   
	     
	   }
	   CURRENT_DOCUMENT = "";
	   update_empty_titles(SUB_DIRECTORY_NAME);
	   editor.setValue("");
	     
      
    }
    
    function save_an_load_file(){
	
      if(CURRENT_DOCUMENT ==""){
	    var name = prompt("Please enter the filename","");
	    if (name!=null && name!=""){	
		  var callback_user  = function(reps){
			CURRENT_DOCUMENT = reps.id;
		  };
	      
		  insert_file(name, editor.getValue(), SUB_DIRECTORY, callback_user ); 
		  setTimeout(function(){ fill_project_list(SUB_DIRECTORY) },5000);
		  update_name_title(name);
		  load_code();
	    }else{
	        alert("The filename can't be empty");
		return;
	    }
	    
      }else{
	      load_code();
	      save_file( editor.getValue() );
      }
       
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

