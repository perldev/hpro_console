    /**
 * Copyright 2013 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


/**
 * @fileoverview Common utility functionality for Google Drive Realtime API,
 * including authorization and file loading. This functionality should serve
 * mostly as a well-documented example, though is usable in its own right.
 */


/**
 * @namespace Realtime client utilities namespace.
 */
    
    
    var ws = new Object;
    var ws_trace = new Object;
    var history = new Array();
    var index = 0;
    var HOST = "127.0.0.1:8080";
    var editor;
    var SESSION_KEY;
    var LOADED = 0;
    var WHOST = "ws://" + HOST+"/websocket/"; //"ws://hd-test-2.ceb.loc:10100";
    function send_req(obj){
		 var Code = $.trim(obj.value);	
		 var Var  = "<p>| -? " + obj.value+"</p>";
		 var Var1 = obj.value;
		 Var1 = Var1.replace("\n","");
		 Var1 = Var1 + " ";
		 obj.value ="";
		 $("#sse").html("<p>| -? " + Var +"</p>");
		 history[$.trim(Var1)] = 1 ;	  
		 index = 0;
		 send(Var1);
		 disable_run();     
    
    }
    function onFileLoaded(doc) {
      var string = doc.getModel().getRoot().get('text');
      string +="\n";      
      editor.setValue(string);
    } 
    function  update_editor(string){
	    editor.setValue(string);
    
    }
    
    function initializeModel(model){
    
	  return;
    }
    function my_after_auth(){
	  $("#authorizeButton").hide("fast");
    } 
   
    function but_search(){
	  var obj = document.getElementById("code");
	  if( $("#code").prop("disabled") )
	      return ;
	  Code = obj.value;
	  if(Code.charAt(Code.length-1) != "."){
			  Code +=".";
			 
	  }   
	  obj.value = Code;  
	  send_req(obj);
    
    }
    function listen(obj, E){
	  if(E.keyCode == 13 ){
		 Code = obj.value;
	  
		if(Code.charAt(Code.length-1) != "."){
			  Code +=".";
			 
	        } 
		obj.value = Code;
		send_req(obj);
	  
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
 				$("#code").attr( { "value": key } );
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
				$("#code").attr(  "value", key  );
				index = i;
				return ;
			  }
			  i++;
			  
		  }
	  
	  
	  
	  }
	  
	  
    }

    function disable_run(){
		  $("#code").prop("disabled", true);    
		  $("#search_but").hide("slow");
    
    }
    function interactive_commands(received_msg){
      
            //alert(received_msg);
            var patt = /^read_term/;
            var result = patt.test(received_msg);
            if(result){
                draw_input();
                return 1;
            }
            patt = /^get_char/;
            result = patt.test(received_msg);
            if(result){
                draw_char_input();
                return 1;
            }
            patt = /^prolog_write/;
            result = patt.test(received_msg);
            if(result){
                var Msg = received_msg.split(",");
                draw_output(Msg[1]);
                ws.send("prolog_write_pong");
                return 1;
            }
            return 0;
      
      }
      function draw_msg(Msg){
      
            $("<p>| -? " + Msg +"</p>").insertBefore("#sse");       
            $("#trace_input").prop("disabled", true);
            $("#code").prop("disabled", false);
            $("#code").focus();    
            
      }
    
      function  draw_char_input(){
      
            $("<p>| -? <input type=\"text\" onkeyup='user_input(this, event)'  maxLength='1' style='width: 10px;'></p>").insertBefore("#sse");      
            $("#trace_input").prop("disabled", true);
            $("#code").prop("disabled", true);
      
     }
    function  draw_input(){
      
            $("<p>| -? <input type=\"text\" onkeyup='user_input(this, event)' size='100'></p>").insertBefore("#sse");       
            $("#trace_input").prop("disabled", true);
            $("#code").prop("disabled", true);
    }
    function draw_output(Msg){
            $("<p>| -? "+Msg+"</p>").insertBefore("#sse");          
            $("#trace_input").prop("disabled", true);
            $("#code").prop("disabled", true);
      
    }
    function enable_run(){
		  $("#code").prop("disabled", false);    
		  $("#search_but").show("slow");
		  $("#code").focus();
    
    }

    function send(Code)
    {
	hide_choose();
	send_txt = Code;
	ws.send(send_txt);
	console.log('Message sent');
    }
    function hide_choose(){
	
	$("#choose_menu").hide("fast");
    
    
    }
    function show_choose(){
	
	$("#choose_menu").show("fast");
    
    
    }
