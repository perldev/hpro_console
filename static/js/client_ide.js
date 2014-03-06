

    
    
    var ws = new Object;
    var ws_trace = new Object;
    var history = new Array();
    var index = 0;
    var wait_answer = 0 ;
    var SESSION_KEY = "";
    var realtimeLoader;
    var NAME_SPACES = {};
    var editor;
    var picker;
    var CurrentDataBase = "";
    var LOADED = 1;
    var CookieName = "ide_doc_path_prolog";  
    var LastProjectCookieName = "ide_last_project_path_prolog";  

    var CURRENT_DOCUMENT = "";
    var CURRENT_NAME = "";
    var PARENT_DIRECTORY="";
    var SUB_DIRECTORY_NAME = "";
    var SUB_DIRECTORY="";
    var WHOST = "ws://" + HOST+"/websocket/";
    var TMP_BUFFER_RESULT={};
   function clean_code(Code){
                    if(Code){
//                	alert(Code);
//                         Code = Code.replace(/%.+/mg,"");
// 			Code = Code.replace(/\r/mg,"");
//                         Code = Code.replace(/(\d+)\.(\d+)/mg,"$1#%#$2");
//                         Code = Code.replace(/=\.\./mg,"#%=#");
                        Code = Code.replace(/[“”]/mg,"\"");
                        Code = $.trim(Code);
                        return Code;
                    }
                    return "";
       
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
	      my_alert("We create a sample  project PrologSamples  in your GoogleDrive ");
	      
// 	      hide("create_new_project");
// 	      show("online_ide_button");
	  };
	  
	  realtimeLoader.new_project( picker_creater, "PrologSamples", PARENT_DIRECTORY );     
	 
      
    }    
//     function after_auth_init_ide(){
//              
//             
//         
//         
//             var Path = readCookie(CookieName);
//             
//             if(Path||Path==""){
//                 PARENT_DIRECTORY = Path;
//                 
//     //          show("online_ide_button");
//     //          hide("create_new_project");
//             }else{  
//                 
//                 create_working_dir();           
//                     
//             }
//         
//         
//         
//     }
    function create_working_dir(){
    	 
      
// 	if(confirm("Could i create a working folder on your google drive?") ){
        
	      var access_token = gapi.auth.getToken("token",null);
	      var callback = function(resp){
		PARENT_DIRECTORY = resp.id;
		createCookie(CookieName, PARENT_DIRECTORY);
		if(confirm("Хотите ли вы загрузить несколько примеров") ){
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
	    
// 	}/*else{
// 	  createCookie(CookieName, "");
	  
	  
/*	}*/
    
      
		      
    }
    function update_empty_titles(Name){
      
      $("#project_title").html("<h6>" + Name+" &gt; new untitled file </h6>");
      
    }
    
    function create_new_project_common(){
	   
	    var Name = prompt("Please enter project's name","ProjectName");
	    if (Name==null || Name=="")
	    {
		my_alert("The name of project can't be empty");
		return;
		
	    }
	    CurrentDataBase = "";   
            $("#database_name_"+CurrentDataBase).removeClass('btn-warning');
            $("#database_name_"+CurrentDataBase).addClass('btn-info');
            $("#make_public_button").show("fast");
            $("#save_to_public_button").hide("fast");
            
            var callback = function(resp){
                
                my_alert("The project "+ Name + " was created successfully");	      
		editor.setValue("your_fist_fact(\""+SUB_DIRECTORY_NAME+"\").");
                CURRENT_DOCUMENT = "";
                SUB_DIRECTORY = resp.id;
                SUB_DIRECTORY_NAME = Name;
                insert_file("init_expert.pl", editor.getValue(), SUB_DIRECTORY, default_file_process );
                update_name_title("init_expert.pl");
                
// 		update_empty_titles(SUB_DIRECTORY_NAME);
// 		Str = "<h5> Project's files: </h5>";
// 		$("#project_files").html(Str);
//                 

		
	    };
	    
	    realtimeLoader.new_project(callback, Name, PARENT_DIRECTORY );     

     
    }
    function listen(obj, E){
	  if(E.keyCode == 13 ){
		Code = $.trim(obj.value);
		if(wait_answer){
			if(Code != "yes." && Code != "no."){
				$("<p class='console_msg'>| -? Enter yes. or no. </p>").insertBefore("#sse");
				scroll_console();
				return;			
			}
		}
		
		if( Code.charAt(Code.length - 1) == "." ){
		
			  var Var  = "<p class='console_msg'>| -? " + obj.value+"</p>";
			  
			  var Var1 = obj.value;
			  Var1 = Var1.replace("\n","");
			  Var1 = Var1 + " ";
			  obj.value ="";
			  $("<p class='console_msg'>| -? " + Var +"</p>").insertBefore("#sse");
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
	 $("#msgs_ide").animate({
			      scrollTop: $("#msgs_ide").get(0).scrollHeight
			    }, 100);
	  
    
    }
    function scroll_trace(){
	 $("#trace_msg").animate({
			      scrollTop: $("#trace_msg").get(0).scrollHeight
			    }, 100);
	  
    
    }
    
    function listen_trace(obj, E){
	  if(E.keyCode == 13 ){
		    Code = $.trim(obj.value);
                    if(Code=="")
                            Code ="yes.";
                        
                    
		    if( Code == "yes."){
			      var Var  = "<p class='trace_msg'>| -? " + obj.value+"</p>";
			      
			      var Var1 = Code;
			      Var1 = Var1 + " ";
			      obj.value ="";
   		      	       $("<p class='trace_msg'>| -? " + Var1 +"</p>").insertBefore("#trace_sse");	    
			      scroll_trace();
			      send_trace(Var1);
       	  	              $("#trace_input").prop("disabled", true);
			      return  ;
		    }
		    if( Code == "no." ){
		          var Var  = "<p class='trace_msg'>| -? " + obj.value+"</p>";
			  var Var1 = Code;
			  Var1 = Var1 + " ";
			  obj.value ="";
			  
			  $("<p class='trace_msg'>| -? " + Var1 +"</p>").insertBefore("#trace_sse");
			   send_trace(Var1);
			   scroll_trace();
   	  	          $("#trace_input").prop("disabled", true);

			  return  ; 
		    }
		    my_alert("Enter 'yes.' or 'no.' please");
			
			  
		}
	  
	  
    }
    function to_console_alert(Msg){
        draw_msg("<strong>" + Msg+"</strong>");        
    }
    
    function draw_msg(Msg){
      
	    $("<p class='console_msg' >| -? " + Msg +"</p>").insertBefore("#sse");	        
	    $("#trace_input").prop("disabled", true);
    	    $("#code").prop("disabled", false);
	    $("#code").focus();	   
	    
    }
    function  draw_char_input(){
      
	    $("<p class='console_msg' >| -? <input type=\"text\" onkeyup='user_input(this, event)'  maxLength='1' style='width: 10px;'></p>").insertBefore("#sse");	    
	    $("#trace_input").prop("disabled", true);
    	    $("#code").prop("disabled", true);
      
    }
    function  draw_input(){
      
	    $("<p class='console_msg' >| -? <input type=\"text\" onkeyup='user_input(this, event)' size='100'></p>").insertBefore("#sse");	    
	    $("#trace_input").prop("disabled", true);
    	    $("#code").prop("disabled", true);
    }
    function draw_output(Msg){
	    $("<p class='console_msg' >| -? "+Msg+"</p>").insertBefore("#sse");	    
	    $("#trace_input").prop("disabled", true);
    	    $("#code").prop("disabled", true);
      
    }
    function user_input(obj, E){
	       if(E.keyCode == 13 ){
			Code = $.trim(obj.value);
			$("<p class='console_msg'>| -? "+Code+" </p>").insertBefore("#sse");
			scroll_console();
			ws.send(Code);
			obj.style.display="none";
				
	      }
     
    }
    function show_trace(){
	  $("#trace").slideDown("slow");
    }
    function close_editor(){   
        
	 $("#container_editor").hide("fast");
         $("#online_ide_button").removeClass("btn-info");
         
    }
    function clear_console(){
	$("p.console_msg").remove();
	clear_trace();
	
    
    }
      function close_console1(){
      
	$("#console").hide("fast");
        $("#console_button").removeClass("btn-info");
	close_trace();
    
    }
    function close_trace(){
	    
	      
	  $("#trace").hide("fast");
    }
    function clear_trace(){

	  $("p.trace_msg").remove();
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
                            error: default_alert
			    }
		);
	    }
	    $("#container_editor").slideDown("slow");
            $("#online_ide_button").addClass("btn-info");
    
    }
    function export_code(){
		my_alert("not implemented");
    
    }
    function load_code_of_expert_system(id){
                      if(id == CurrentDataBase){
                            show_online();
                            return ;
                      }          
                      open_directory(id);
        
    }
    
    function open_directory(id){
           
             gapi.client.load('drive', 'v2', function() {
                retrieveAllFiles(read_file_names, id)
            });              
        
    }
    function read_file_names(Result){

            for(item in Result){

                    if(Result[item]){
                        open_file(Result[item].id);
                        return ;
                    }else{
                            my_alert("I can't read the content of directory");
                    }
                    
            }
    }
    function list_namespace(){
          if( document.getElementById("own_expert_systems") ) {
                        var session = gapi.auth.getToken("token",null);
                        var google_session = session.access_token;
                        $("#own_expert_systems").html("My Public Expert Systems&nbsp;:&nbsp;");    
              
                        var new_function = function(Data){
                                                var array = $.map(Data, function(value, key) {
                                                            show_own_expert_system_button(key, value);
                                                });           
                                    };           
                        $.ajax(
                            {
                                dataType: "json",
                                url: "http://" + HOST +"/command/list_namespace/"+google_session,
                                success: new_function,
                                error: default_alert
                            }
                        );
           }
        
        
    }
    function show_own_expert_system_button(key, Name){
                       NAME_SPACES[key] = 1;
                       var click = 'load_code_of_expert_system("'+key+'")';
                       var Res ="<span id=\"database_name_"+key+"\" class='btn btn-info' style='height:20px' onclick='"+ click +"' >"+ Name +"</span>&nbsp;";
                       $( Res ).appendTo( "#own_expert_systems" );

        
    }
    
    function make_public(){
      if(SUB_DIRECTORY){
            gapi.client.load('drive', 'v2', function() {
                retrieveAllFiles(public_whole_system, SUB_DIRECTORY);
            });          
        }else{
            my_alert("You didn't choose the project")
        } 
         
    }
    function public_whole_system(Result){
            TMP_BUFFER_RESULT = { };
            for(item in Result){
                    TMP_BUFFER_RESULT[Result[item].id] = {"ready":"wait", "result": ""};
                    
            }
            for(item in Result){
                        var id = Result[item].id;
                        realtimeLoader.get_file(Result[item].id, 
                                function(Data, Meta){
                                    TMP_BUFFER_RESULT[Meta['id']] = {"ready":"yes","result": Data};                                   
                                }                                    
                        );
                
            }
            setTimeout(check_all_project2public, 1000);
            
    }
    function check_all_project2public(){
        
         console.log(TMP_BUFFER_RESULT);
         for(item in TMP_BUFFER_RESULT){
                if(TMP_BUFFER_RESULT[item]["ready"] == "wait"){
                    setTimeout(check_all_project2public, 1000);
                    return 
                }    

         }   
         var tmp="";
         for(item in TMP_BUFFER_RESULT){
            tmp += TMP_BUFFER_RESULT[item]["result"];             
         }
         make_public_low(tmp);
    } 
    
    function  make_public_low(Code){
                    var new_function = function(Data){
//                        $("<p>| -? " + Data +"</p>").appendTo("#msgs");
                          my_alert("Project '" + SUB_DIRECTORY_NAME + "' is avalible now at the network, you can manage it in tab 'Managing' " );
                          list_namespace();
                          hide_block_div();                          
                    }
                    //hack for numbers
                    Code = clean_code(Code);
                    var session = gapi.auth.getToken("token",null); 
                    
                    if(session){
                          var google_session = session.access_token;
                          var  params = { code: Code   };
                          $("#make_public_button").hide("fast");
                          $("#save_to_public_button").show("fast");
                          
                          if(CURRENT_NAME){
                                    $.ajax({
                                        type: "POST",
                                        url: "http://" + HOST +"/command/make_public/"+ google_session +"/"+SUB_DIRECTORY_NAME +"/"+SUB_DIRECTORY,
                                        data: params,
                                        success: new_function,
                                        error: default_alert
                                        }
                                    );
                          }else{
                                //TODO add form for name 
                                my_alert("Save file before! Press key Run  for it");                              
                          }
                    }
            
        
        
        
    }
     
    function save_public(){
      if(SUB_DIRECTORY){
            gapi.client.load('drive', 'v2', function() {
                retrieveAllFiles(save_whole_system, SUB_DIRECTORY);
            
            });          
        }else{
            my_alert("You didn't choose the project")
        } 
         
    }
    function save_whole_system(Result){
            TMP_BUFFER_RESULT = { };
            for(item in Result){
                    TMP_BUFFER_RESULT[Result[item].id] = {"ready":"wait", "result": ""};
                    
            }
            for(item in Result){
        //             Str += "<a class=\"btn\" href=\"javascript:open_file('"+Result[item].id+"')\">"+ Result[item].title +" </a>";
                        var id = Result[item].id;
                        realtimeLoader.get_file(Result[item].id, 
                                function(Data, Meta){
                                    
                                    TMP_BUFFER_RESULT[Meta['id']] = {"ready":"yes","result": Data};
                                   
                                }                                    
                        );
                
            }
            setTimeout(check_all_project2save, 1000);
            
    }
    function check_all_project2save(){
        
         console.log(TMP_BUFFER_RESULT);
         for(item in TMP_BUFFER_RESULT){
                if(TMP_BUFFER_RESULT[item]["ready"] == "wait"){
                    setTimeout(check_all_project2save, 1000);
                    return 
                }    

         }   
         var tmp="";
         for(item in TMP_BUFFER_RESULT){
            tmp += TMP_BUFFER_RESULT[item]["result"];             
         }
         save_public_low(tmp);
    } 
    
    
    
    function save_public_low(Code){
                    var new_function = function(Data){
//                        $("<p>| -? " + Data +"</p>").appendTo("#msgs");
                          my_alert("Project '" + SUB_DIRECTORY_NAME + "' has been saved, you can manage it in tab 'Managing' " );
                          // TODO get_namespace_list
                    }
                    
                    //hack for numbers
                    Code = clean_code(Code);
                    
                    var session = gapi.auth.getToken("token",null); 
                    if(session){
                          var google_session = session.access_token;
                          var  params = { code: Code   };
                          if(CURRENT_NAME){
                                    $.ajax({
                                        type: "POST",
                                        url: "http://" + HOST +"/command/save_public/"+ google_session +"/"+SUB_DIRECTORY_NAME +"/"+SUB_DIRECTORY,
                                        data: params,
                                        success: new_function,
                                        error: default_alert
                                        }
                                    );
                          }else{
                                //TODO add form for name 
                                my_alert("Save file before! Press key Run  for it");                              
                          }
                    }               
    }    
    function load_code(){
		    var new_function = function(Data){
                          clear_console();
                          to_console_alert(CURRENT_NAME + " is loaded, type 'help.' for getting started");
			  open_console();
		    }
		    var Code = editor.getValue(),
		    //hack for numbers
                    Code = clean_code(Code);

		    var  params = { code: Code   };
	            $.ajax({
                        type: "POST",
                        url: "http://" + HOST +"/command/upload_code/"+ SESSION_KEY,
                        data: params,
                        success: new_function,
                        error: default_alert
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
         $("#help_button").addClass("btn-info");
    
    }
    function close_help(){
	  $("#container_help").hide("fast");
           $("#help_button").removeClass("btn-info");
    }
    function close_console(){
	 	  document.getElementById("container").innerHTML="Good bye";
		  ws.close();
    
    }
    function start_editor(){
        
        Key = Math.random();
        // Handler for .ready() called.
        
        ws = new WebSocket(WHOST+Key);
        SESSION_KEY = Key;
        ws.onopen = function() {
            console.log('Connected');
        };
        ws.onmessage = function (evt)
        {
            var received_msg = evt.data;
            console.log("Received: " + received_msg);
            var obj =  document.getElementById('msgs_ide');
            
//          $("<p>| -? " + received_msg +"</p>").appendTo("#msgs");
            var patt=/looking next \?/;
            var result=patt.test(received_msg);
            if(result){
                wait_answer = 1;
            }
            
            if(interactive_commands(received_msg)){  
                  return ;
            }
            
            draw_msg(received_msg); 
            scroll_console();
            
            //      obj.scrollTo(0, obj.scrollHeight);
            
        };
        ws.onclose = function()
        {
            console.log('Connection closed');
        };

        
        ws_trace = new WebSocket(WHOST+"trace/" + Key);
        ws_trace.onopen = function() {
            console.log('Connected');
        };
        ws_trace.onmessage = function (evt)
        {
            var received_msg = evt.data;
            console.log("Received: " + received_msg);
            if(received_msg !="finish"){
            
                $("#trace_input").prop("disabled", false);
                $("#trace_input").focus();    
                $("<p class='trace_msg'>| -? " + received_msg +"</p>").insertBefore("#trace_sse");            
                scroll_trace();

            }
            

        };
        ws_trace.onclose = function()
        {
            console.log('Connection closed');
        };
        editor = ace.edit("editor");
        editor.getSession().setMode("ace/mode/prolog");
        
        $( document ).ajaxError(function() {
//             $( "div#block_window" ).show("fast");
            $( "div#server_alert" ).show("fast");
            
        });
      
        
        
        
        
    }
    function create_server_session(ObjSession){
            var Session = ObjSession.access_token;
            if( document.getElementById("own_expert_systems") ) {
                              
               
                
                        var new_function = function(Data){
                                                var array = $.map(Data, function(value, key) {
                                                            show_own_expert_system_button(key, value);
                                                });
                                                var new_function1 = function(Data){        
                                                        PARENT_DIRECTORY = Data;
                                                        var LastFileId = readCookie(LastProjectCookieName);
                                                        start_editor();
                                                        if(LastFileId)
                                                             open_file(LastFileId);
                                                        
                                                };   
                                                $.ajax(
                                                  {
                                                    url: "http://" + HOST +"/command/find_workspace/"+Session,
                                                    success: new_function1,
                                                    error: default_alert
                                                 }
                                               ); 
                                                
                                                
      
                                    };  
                        $.ajax(
                            {
                                dataType: "json",
                                url: "http://" + HOST +"/command/create_command_session/"+Session,
                                success: new_function,
                                error: default_alert
                            }
                        ).fail(function() { 
                                            var new_function1 = function(Data){        
                                                        PARENT_DIRECTORY = Data;
                                                        var LastFileId = readCookie(LastProjectCookieName);
                                                        start_editor();
                                                        if(LastFileId)
                                                             open_file(LastFileId);
                                                        
                                                };   
                                                $.ajax(
                                                  {
                                                    url: "http://" + HOST +"/command/find_workspace/"+Session,
                                                    success: new_function1,
                                                    error: default_alert
                                                 }
                                               ); 
                            
                                                        
                        });
                        
                        
                        
                        
                        
                        
           }
                        
          
                    
                   
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
	  
//  	  if(PARENT_DIRECTORY && PARENT_DIRECTORY != "")
//           view_d.setParent(PARENT_DIRECTORY);  
                
                
//       view.setMimeTypes("txt/plain");    
	  picker = new google.picker.PickerBuilder()
	     
          .setAppId('768399903870')
// 	  .setOAuthToken(access_token) //Optional: The auth token used in the current Drive API session.
//           .addView(view)
	  .addView(view_d)
          .addView(upload_v)
          .setCallback(pickerCallback)
          .build();
       
    }
    function update_editor_soft(string, meta){
        
          editor.setValue(clean_br(  string ) );          
          CURRENT_NAME = meta.title;
          CURRENT_DOCUMENT = meta.id;     
          SUB_DIRECTORY =  meta.parents[0].id;
          hide_block_div();
          createCookie(LastProjectCookieName, CURRENT_DOCUMENT);
          update_name_title(CURRENT_NAME);
          
    }
    
    function  update_editor(string, meta){
	  editor.setValue(clean_br(string));	    
	  CURRENT_NAME = meta.title;
          CURRENT_DOCUMENT = meta.id;

  	  SUB_DIRECTORY =  meta.parents[0].id;
          if(NAME_SPACES[SUB_DIRECTORY]){
                      $("#database_name_" + CurrentDataBase).removeClass('btn-warning');
                      $("#database_name_" + CurrentDataBase).addClass('btn-info');  
              
                      CurrentDataBase = SUB_DIRECTORY;   
                      $("#database_name_"+CurrentDataBase).addClass('btn-warning');
                      $("#database_name_"+CurrentDataBase).removeClass('btn-info');
                      $("#make_public_button").hide("fast");
                      $("#save_to_public_button").show("fast");
                      
                      
          }else{
                      CurrentDataBase = "";   
                      $("#make_public_button").show("fast");
                      $("#save_to_public_button").hide("fast");
              
          }
	  update_title();
          hide_block_div();
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
    function interface_open_file(FileId){
            if(FileId == CURRENT_DOCUMENT)
                    return;
        
            
            save_file(  editor.getValue()  );
            realtimeLoader.get_file(FileId, update_editor_soft);
            
            
    }
    function hide_block_div(){
         $( "div#block_window" ).hide("fast");
    }
    function show_block_div(){
        $( "div#block_window" ).show("fast");
    }
    function open_file(FileId){
            realtimeLoader.get_file(FileId, update_editor);  
            createCookie(LastProjectCookieName, FileId);
    }
    function process(Result){
      
      Str = "<h5> Project's files: </h5>";
      for(item in Result){
	    Str += "<a class=\"btn\" href=\"javascript:interface_open_file('"+Result[item].id+"')\">"+ Result[item].title +" </a>";
      }
      $("#project_files").html(Str);
    }
    function fill_project_list(Dir){
      
        gapi.client.load('drive', 'v2', function() {
	    retrieveAllFiles(process, Dir);
	}); 
    }
    function compile_project(){
        
        
        if(SUB_DIRECTORY){
            if(CURRENT_DOCUMENT){
                save_file(editor.getValue());
            }else{
                
                if(confirm("Do you want to save current file? ")){
                   save_file(editor.getValue());
                }
                
            }
            gapi.client.load('drive', 'v2', function() {
                show_block_div();
                retrieveAllFiles(compile_system, SUB_DIRECTORY);
            
            });          
        } 
         
    }
    function compile_system(Result){
            TMP_BUFFER_RESULT = { };
             
            
           
            for(item in Result){
                    TMP_BUFFER_RESULT[Result[item].id] = {"ready":"wait", "result": ""};
                    
            }
            for(item in Result){
                        var id = Result[item].id;
                        realtimeLoader.get_file(Result[item].id, 
                                function(Data, Meta){
                                    
                                    TMP_BUFFER_RESULT[Meta['id']] = {"ready":"yes","result": Data};
                                   
                                }                                    
                        );
                
            }
            setTimeout(check_all_project, 1000);
            
    }
    function check_all_project(){
        
         for(item in TMP_BUFFER_RESULT){
                if(TMP_BUFFER_RESULT[item]["ready"] == "wait"){
                    setTimeout(check_all_project, 1000);
                    return 
                }    

         }   
         var tmp="";
         for(item in TMP_BUFFER_RESULT){
            tmp += "\n" + TMP_BUFFER_RESULT[item]["result"];             
         }
         load_string_code(tmp);
    }
    function load_string_code(Code ){
        
                    var new_function = function(Data){
                          if(Data =="yes"){
                              clear_console();
                              to_console_alert("Project '"+SUB_DIRECTORY_NAME+"'is loaded type 'help.' for getting started");

                              open_console();
			  }else{
				my_alert("there is mistake during compilation" + Data);

			  }
                          hide_block_div();
                        
                    }
                    //hack for numbers
                    Code = clean_code(Code);
              
                    var  params = { code: Code   };
                    $.ajax({
                        type: "POST",
                        url: "http://" + HOST +"/command/upload_code/"+ SESSION_KEY,
                        data: params,
                        success: new_function,
                        error: default_alert
                        }
                      );
    
        
    }
    function clean_br(Code){
	
	    Code =  Code.replace(/^\s*[\r\n]/gm,"");
	    return Code;

    }   
    function save_file(Code){
	   Code =  clean_br(Code); 
///ДЕБИЛИЗМ СОХРАНЯТЬ ФАЙЛЫ И В Google Doc 
           
           
           if(CURRENT_DOCUMENT){
                    gd_updateFile(CURRENT_DOCUMENT, SUB_DIRECTORY, Code, 0 );
           }else{
                  var name = prompt("Please enter the filename","");
                  if (name!=null && name!=""){        
                    insert_file(name, editor.getValue(), SUB_DIRECTORY, default_file_process ); 
                    update_name_title(name);
                  }else{
                        my_alert("Filename can't be null");    
                  }
               
          }
           
      
    }
    function default_file_process(reps){
        
        
          CURRENT_DOCUMENT = reps.id;
          createCookie(LastProjectCookieName, CURRENT_DOCUMENT);
           fill_project_list(SUB_DIRECTORY);
        
    }
    function new_file(){
      
    
	  if(SUB_DIRECTORY==""){
		my_alert("Create project  at first");
		return;
	    
	    
	  }
	   var  text = editor.getValue();
	   if(CURRENT_DOCUMENT !=""){
		if(confirm("Do you want to save current file")){
		      save_file(  editor.getValue()  );		  
		}
	     
	   }
	   if(text!=""&&CURRENT_DOCUMENT==""){
	     if(confirm("Do you want to save current file")){
		var name = prompt("Please enter the filename","");
		if (name!=null && name!=""){	
		  
		  insert_file(name, text, SUB_DIRECTORY, default_file_process ); 
	        }
	     
	    }else{
		   my_alert("The filename can't be empty");
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
	      
		  insert_file(name, editor.getValue() , SUB_DIRECTORY, callback_user ); 
		  setTimeout(function(){ fill_project_list(SUB_DIRECTORY) },5000);
		  update_name_title(name);
		  load_code();
	    }else{
	        my_alert("The filename can't be empty");
		return;
	    }
	    
      }else{
	      load_code();
	      save_file( editor.getValue() );
      }
       
    }
    function interactive_commands(received_msg){
      
	    //my_alert(received_msg);
	    var patt = /^read_term/;
	    var result = patt.test(received_msg);
	    if(result){
		draw_input();
		scroll_console();
		return 1;
	    }
	    patt = /^get_char/;
	    result = patt.test(received_msg);
	    if(result){
		draw_char_input();
		scroll_console();
		return 1;
	    }
	    patt = /^prolog_write/;
	    result = patt.test(received_msg);
	    if(result){
		var Msg = received_msg.split("prolog_write,");
		draw_output(Msg[1]);
		scroll_console();
		ws.send("prolog_write_pong");
		return 1;
	    }
	    return 0;
      
    }
    function open_console()
    {
	if (!("WebSocket" in window)) {
	    my_alert("This browser does not support WebSockets");
	    return;
	}
	close_editor();
	close_help();
        
	$("#console").slideDown("slow");
	$("#code").prop("disabled", false);
	$("#code").focus();
        $("#console_button").addClass("btn-info");
	show_trace();
// // 	document.getElementById("code").value='';
// 	$("#code").focus();
	

	/* @todo: Change to your own server IP address */
	
    } 

