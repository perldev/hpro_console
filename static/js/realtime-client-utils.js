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

 "use strict";

/**
 * @fileoverview Common utility functionality for Google Drive Realtime API,
 * including authorization and file loading. This functionality should serve
 * mostly as a well-documented example, though is usable in its own right.
 */


/**
 * @namespace Realtime client utilities namespace.
 */
var rtclient = rtclient || {}


/**
 * OAuth 2.0 scope for installing Drive Apps.
 * @const
 */
rtclient.INSTALL_SCOPE = 'https://www.googleapis.com/auth/drive.install'


/**
 * OAuth 2.0 scope for opening and creating files.
 * @const
 */
rtclient.FILE_SCOPE = 'https://www.googleapis.com/auth/drive'


/**
 * OAuth 2.0 scope for accessing the user's ID.
 * @const
 */
rtclient.OPENID_SCOPE = 'openid'


/**
 * MIME type for newly created Realtime files.
 * @const
 */
rtclient.REALTIME_MIMETYPE = 'application/vnd.google-apps.drive-sdk';


/**
 * Parses the query parameters to this page and returns them as an object.
 * @function
 */
rtclient.getParams = function() {
  var params = {};
  var queryString = window.location.search;
  if (queryString) {
    // split up the query string and store in an object
    var paramStrs = queryString.slice(1).split("&");
    for (var i = 0; i < paramStrs.length; i++) {
      var paramStr = paramStrs[i].split("=");
      params[paramStr[0]] = unescape(paramStr[1]);
    }
  }
  console.log(params);
  
  return params;
}


/**
 * Instance of the query parameters.
 */
rtclient.params = rtclient.getParams();


/**
 * Fetches an option from options or a default value, logging an error if
 * neither is available.
 * @param options {Object} containing options.
 * @param key {string} option key.
 * @param defaultValue {Object} default option value (optional).
 */
rtclient.getOption = function(options, key, defaultValue) {
  var value = options[key] == undefined ? defaultValue : options[key];
  if (value == undefined) {
    console.error(key + ' should be present in the options.');
  }
  console.log(value);
  return value;
}


/**
 * Creates a new Authorizer from the options.
 * @constructor
 * @param options {Object} for authorizer. Two keys are required as mandatory, these are:
 *
 *    1. "clientId", the Client ID from the APIs Console
 */
rtclient.Authorizer = function(options) {
  this.clientId = rtclient.getOption(options, 'clientId');
  // Get the user ID if it's available in the state query parameter.
  this.userId = rtclient.params['userId'];
  this.authButton = document.getElementById(rtclient.getOption(options, 'authButtonElementId'));
}


/**
 * Start the authorization process.
 * @param onAuthComplete {Function} to call once authorization has completed.
 */
rtclient.Authorizer.prototype.start = function(onAuthComplete) {
  var _this = this;
  gapi.load('auth:client,drive-realtime,drive-share', function() {
    _this.authorize(onAuthComplete);
  });
}


/**
 * Reauthorize the client with no callback (used for authorization failure).
 * @param onAuthComplete {Function} to call once authorization has completed.
 */
rtclient.Authorizer.prototype.authorize = function(onAuthComplete) {
  var clientId = this.clientId;
  var userId = this.userId;
  var _this = this;

  var handleAuthResult = function(authResult) {
    if (authResult && !authResult.error) {
      _this.authButton.disabled = true;
      _this.fetchUserId(onAuthComplete);
    } else {
      _this.authButton.disabled = false;
      _this.authButton.onclick = authorizeWithPopup;
    }
  };

  var authorizeWithPopup = function() {
    gapi.auth.authorize({
      client_id: clientId,
      scope: [
        rtclient.INSTALL_SCOPE,
        rtclient.FILE_SCOPE,
        rtclient.OPENID_SCOPE
      ],
      user_id: userId,
      immediate: false
    }, handleAuthResult);
    console.log(clientId);
  };

  // Try with no popups first.
  gapi.auth.authorize({
    client_id: clientId,
    scope: [
      rtclient.INSTALL_SCOPE,
      rtclient.FILE_SCOPE,
      rtclient.OPENID_SCOPE
    ],
    user_id: userId,
    immediate: true
  }, handleAuthResult);
}


/**
 * Fetch the user ID using the UserInfo API and save it locally.
 * @param callback {Function} the callback to call after user ID has been
 *     fetched.
 */
rtclient.Authorizer.prototype.fetchUserId = function(callback) {
  var _this = this;
  gapi.client.load('oauth2', 'v2', function() {
    gapi.client.oauth2.userinfo.get().execute(function(resp) {
      if (resp.id) {
        _this.userId = resp.id;
      }
      if (callback) {
        callback();
      }
    });
  });
};

/**
 * Creates a new Realtime file.
 * @param title {string} title of the newly created file.
 * @param callback {Function} the callback to call after creation.
 */


rtclient.createRealtimeFile = function(title, callback) {
  gapi.client.load('drive', 'v2', function() {
    gapi.client.drive.files.insert({
      'resource': {
        mimeType: rtclient.REALTIME_MIMETYPE,
        title: title
      }
    }).execute(callback);
  });
}


/**
 * Fetches the metadata for a Realtime file.
 * @param fileId {string} the file to load metadata for.
 * @param callback {Function} the callback to be called on completion, with signature:
 *
 *    function onGetFileMetadata(file) {}
 *
 * where the file parameter is a Google Drive API file resource instance.
 */
rtclient.getFileMetadata = function(fileId, callback) {
  gapi.client.load('drive', 'v2', function() {
    gapi.client.drive.files.get({
      'fileId' : fileId
    }).execute(callback);
  });
}


/**
 * Parses the state parameter passed from the Drive user interface after Open
 * With operations.
 * @param stateParam {Object} the state query parameter as an object or null if
 *     parsing failed.
 */
rtclient.parseState = function(stateParam) {
  try {
    var stateObj = JSON.parse(stateParam);
    return stateObj;
  } catch(e) {
    return null;
  }
}


/**
 * Redirects the browser back to the current page with an appropriate file ID.
 * @param fileId {string} the file ID to redirect to.
 * @param userId {string} the user ID to redirect to.
 */
rtclient.redirectTo = function(fileId, userId) {
  var params = [];
  if (fileId) {
    params.push('fileId=' + fileId);
  }
  if (userId) {
    params.push('userId=' + userId);
  }
  // Naive URL construction.
  window.location.href = params.length == 0 ? '/' : ('?' + params.join('&'));
}


/**
 * Handles authorizing, parsing query parameters, loading and creating Realtime
 * documents.
 * @constructor
 * @param options {Object} options for loader. Four keys are required as mandatory, these are:
 *
 *    1. "clientId", the Client ID from the APIs Console
 *    2. "initializeModel", the callback to call when the file is loaded.
 *    3. "onFileLoaded", the callback to call when the model is first created.
 *
 * and one key is optional:
 *
 *    1. "defaultTitle", the title of newly created Realtime files.
 */
rtclient.RealtimeLoader = function(options) {
  // Initialize configuration variables.
  this.onFileLoaded = rtclient.getOption(options, 'onFileLoaded');
  this.initializeModel = rtclient.getOption(options, 'initializeModel');
  this.registerTypes = rtclient.getOption(options, 'registerTypes', function(){})
  this.autoCreate = rtclient.getOption(options, 'autoCreate', false); // This tells us if need to we automatically create a file after auth.
  this.defaultTitle = rtclient.getOption(options, 'defaultTitle', 'Common Code');
  
//   this.fileId ="0B-GDhU5T7c8kUnd5bFpkZE9uS1E"; //"1jarDQrJ5a8Nbsb9umKcs2XQUvT4j-WstTWhV1bnoGKg";
  this.authorizer = new rtclient.Authorizer(options);
}


/**
 * Starts the loader by authorizing.
 * @param callback {Function} afterAuth callback called after authorization.
 */
rtclient.RealtimeLoader.prototype.start = function(afterAuth) {
  // Bind to local context to make them suitable for callbacks.
  var _this = this;
  this.authorizer.start(function() {
    if (_this.registerTypes) {
      _this.registerTypes();
    }
    if (afterAuth) {
      afterAuth();
    }
//     _this.load();
  });
}

rtclient.RealtimeLoader.prototype.new_project = function(callback){
	
  var access_token = gapi.auth.getToken("token",null);
   var request = gapi.client.request({
       'path': '/drive/v2/files/',
       'method': 'POST',
       'headers': {
           'Content-Type': 'application/json',
           'Authorization': 'Bearer ' + access_token.access_token,             
       },
       'body':{
           "title" : "PrologProject",
           "mimeType" : "application/vnd.google-apps.folder",
       }
   });
   request.execute( callback  );    

     
}
function insert_file(Title, FolderID){

  var fileData = new Object();
  fileData.fileName = Title + ".pl";
  fileData.type = 'application/octet-stream';
  
  const boundary = '-------314159265358979323846';
  const delimiter = "\r\n--" + boundary + "\r\n";
  const close_delim = "\r\n--" + boundary + "--";

//   var reader = new FileReader();
//   reader.readAsBinaryString(fileData);
//   reader.onload = function(e) {
    var contentType = fileData.type || 'application/octet-stream';
    var metadata = {
       'title': fileData.fileName,
       'mimeType': contentType,
       'parents' : [{
		      "kind": "drive#parentReference",
		      "id": FolderID,
		      "isRoot": false
		    }]
    };

    var base64Data = btoa("first");
    var multipartRequestBody =
        delimiter +
        'Content-Type: application/json\r\n\r\n' +
        JSON.stringify(metadata) +
        delimiter +
        'Content-Type: ' + contentType + '\r\n' +
        'Content-Transfer-Encoding: base64\r\n' +
        '\r\n' +
        base64Data +
        close_delim;

    var request = gapi.client.request({
        'path': "/upload/drive/v2/files",
        'method': 'POST',
        'params': {'uploadType': 'multipart'},
        'headers': {
          'Content-Type': 'multipart/mixed; boundary="' + boundary + '"'
        },
        'body': multipartRequestBody});

     var callback =  function(resp){
	  gd_updateFile(resp.id, FolderID, SampleCode[Title], 0 )  
     }
     request.execute(callback);  
}

function gd_updateFile(fileId, folderId, text, callback) {

    const boundary = '-------314159265358979323846';
    const delimiter = "\r\n--" + boundary + "\r\n";
    const close_delim = "\r\n--" + boundary + "--";

    var contentType ='application/octet-stream'; // "text/plain";
    var metadata = {'mimeType': contentType,};

    var multipartRequestBody =
        delimiter +  'Content-Type: application/json\r\n\r\n' +
        JSON.stringify(metadata) +
        delimiter + 'Content-Type: ' + contentType + '\r\n' + '\r\n' +
        text +
        close_delim;

    if (!callback) { callback = function(file) { return }; }

    gapi.client.request({
        'path': '/upload/drive/v2/files/'+folderId+"?fileId="+fileId+"&uploadType=multipart",
        'method': 'PUT',
        'params': {'fileId': fileId, 'uploadType': 'multipart'},
        'headers': {'Content-Type': 'multipart/mixed; boundary="' + boundary + '"'},
        'body': multipartRequestBody,
        callback:callback,
    });
    
}


rtclient.RealtimeLoader.prototype.get_file =  function(fileId, callback){
    
  
	var handleErrors = function(e) {
	if(e.type == gapi.drive.realtime.ErrorType.TOKEN_REFRESH_REQUIRED) {
	  authorizer.authorize();
	} else if(e.type == gapi.drive.realtime.ErrorType.CLIENT_ERROR) {
	  alert("An Error happened: " + e.message);
    //       window.location.href= "/console.html";
	} else if(e.type == gapi.drive.realtime.ErrorType.NOT_FOUND) {
	  alert("The file was not found. It does not exist or you do not have read access to the file.");
    //       window.location.href= "/console.html";
	}
       };

	var request = gapi.client.request({
	  'fileId': fileId,
	   method: 'GET',
	   path: "/drive/v2/files/"+fileId
	});
	request.execute(function(resp) {
	    downloadFile(resp, callback);

	});

	return;
  
}



function downloadFile(file, callback) {
	if (file.downloadUrl) {
	  var accessToken = gapi.auth.getToken().access_token;
	  var xhr = new XMLHttpRequest();
	  xhr.open('GET', file.downloadUrl);
	  xhr.setRequestHeader('Authorization', 'Bearer ' + accessToken);
	  xhr.onload = function() {
	    callback(xhr.responseText);
	  };
	  xhr.onerror = function() {
	    callback(null);
	  };
	  xhr.send();
	} else {
	  callback(null);
	}
}

/**
 * Loads or creates a Realtime file depending on the fileId and state query
 * parameters.
 */
rtclient.RealtimeLoader.prototype.load = function() {
  var fileId = rtclient.params['fileId'];
  var userId = this.authorizer.userId;
  var state = rtclient.params['state'];
  // Creating the error callback.
  var authorizer = this.authorizer;
  var handleErrors = function(e) {
    if(e.type == gapi.drive.realtime.ErrorType.TOKEN_REFRESH_REQUIRED) {
      authorizer.authorize();
    } else if(e.type == gapi.drive.realtime.ErrorType.CLIENT_ERROR) {
      alert("An Error happened: " + e.message);
//       window.location.href= "/";
    } else if(e.type == gapi.drive.realtime.ErrorType.NOT_FOUND) {
      alert("The file was not found. It does not exist or you do not have read access to the file.");
//       window.location.href= "/";
    }
  };


  // We have a file ID in the query parameters, so we will use it to load a file.
  if (fileId) {
    gapi.drive.realtime.load(fileId, this.onFileLoaded, this.initializeModel, handleErrors);
    return;
  }

  // We have a state parameter being redirected from the Drive UI. We will parse
  // it and redirect to the fileId contained.
  else if (state) {
    var stateObj = rtclient.parseState(state);
    // If opening a file from Drive.
    if (stateObj.action == "open") {
      fileId = stateObj.ids[0];
      userId = stateObj.userId;
      rtclient.redirectTo(fileId, userId);
      return;
    }
  }

  if (this.autoCreate) {
    this.createNewFileAndRedirect();
  }
}


/**
 * Creates a new file and redirects to the URL to load it.
 */
rtclient.RealtimeLoader.prototype.createNewFileAndRedirect = function() {
  //No fileId or state have been passed. We create a new Realtime file and
  // redirect to it.
  var _this = this;
  rtclient.createRealtimeFile(this.defaultTitle, function(file) {
    if (file.id) {
      rtclient.redirectTo(file.id, _this.authorizer.userId);
    }
    // File failed to be created, log why and do not attempt to redirect.
    else {
      console.error('Error creating file.');
      console.error(file);
    }
  });
}

    
    
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

