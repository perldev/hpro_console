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
    var realtimeOptions = {
      /**
       * Client ID from the APIs Console.
       */
      clientId: '768399903870.apps.googleusercontent.com',

      /**
       * The ID of the button to click to authorize. Must be a DOM element ID.
       */
      authButtonElementId: 'authorizeButton',

      /**
       * Function to be called when a Realtime model is first created.
       */
      initializeModel: initializeModel,

      /**
       * Autocreate files right after auth automatically.
       */
      autoCreate: false,

      /**
       * Autocreate files right after auth automatically.
       */
       defaultTitle: "New  Prolog Code",

      /**
       * Function to be called every time a Realtime file is loaded.
       */
       onFileLoaded: onFileLoaded
    };

    /**
     * Start the Realtime loader with the options.
     */
var realtimeLoader;

function onFileLoaded(doc) {
      var string = doc.getModel().getRoot().get('text');
      string +="\n";      
      editor.setValue(string);
}



function startRealtime(my_after_auth) {

            realtimeLoader = new rtclient.RealtimeLoader(realtimeOptions);
            realtimeLoader.start(my_after_auth);
      
 }
function initializeModel(model){
    
          return;
}

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
rtclient.REALTIME_MIMETYPE = 'application/vnd.google-apps.document';//'application/vnd.google-apps.drive-sdk';


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
      afterAuth(  );
    }
//     _this.load();
  });
}

rtclient.RealtimeLoader.prototype.new_project = function(callback, Name, Parent){
	
   var access_token = gapi.auth.getToken("token",null);
       
   var parents = [];
   if(Parent&&Parent!=""){
		    parents =  [{
			    "kind": "drive#parentReference",
			    "id": Parent,
			     "isRoot": false
		    }];
    
    }
   var request = gapi.client.request({
       'path': '/drive/v2/files/',
       'method': 'POST',
       'headers': {
           'Content-Type': 'application/json',
           'Authorization': 'Bearer ' + access_token.access_token,             
       },      
       'body':{
           "title" : Name,
           "mimeType" : "application/vnd.google-apps.folder",
	   'parents' : parents
       }
   });
   request.execute( callback  );    

     
}
function insert_file(Title, Code, Parent, callback_user ){

  var fileData = new Object();
  fileData.fileName = Title;
  fileData.type = "text/plain" //'application/octet-stream';
  
  var boundary = '-------314159265358979323846';
  var delimiter = "\r\n--" + boundary + "\r\n";
  var close_delim = "\r\n--" + boundary + "--";

//   var reader = new FileReader();
//   reader.readAsBinaryString(fileData);
//   reader.onload = function(e) {
    var contentType = fileData.type || 'application/octet-stream';
    var parents = [];
    if(Parent&&Parent!=""){
		    parents =  [{
		      "kind": "drive#parentReference",
		      "id": Parent,
		      "isRoot": false
		    }];
	 
	}
    
    var metadata = {
       'title': fileData.fileName,
       'mimeType': contentType,
       'parents' : parents 
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
        'params': {'uploadType': 'multipart','convert':'true'},
        'headers': {
          'Content-Type': 'multipart/mixed; boundary="' + boundary + '"'
        },
        'body': multipartRequestBody});

     var callback =  function(resp){
	    
          if(callback_user)
	      callback_user(resp);
	  gd_updateFile(resp.id, Parent, Code, 0 )  
     }
     request.execute(callback);  
}

function gd_updateFile(fileId, folderId, text, callback) {

    var boundary = '-------314159265358979323846';
    var delimiter = "\r\n--" + boundary + "\r\n";
    var close_delim = "\r\n--" + boundary + "--";

    var contentType ="text/plain"; //'application/octet-stream'; // "text/plain";
    var metadata = {'mimeType': contentType,};

    var multipartRequestBody =
        delimiter +  'Content-Type: application/json\r\n\r\n' +
        JSON.stringify(metadata) +
        delimiter + 'Content-Type: ' + contentType + '\r\n' + '\r\n' +
        text +
        close_delim;

    if (!callback) { callback = function(file) {  }; }
    var ReqStr="";
    if(folderId&&folderId!=""){
      ReqStr = "/upload/drive/v2/files/"+folderId+"?fileId="+fileId+"&uploadType=multipart";
      
    }else{
      ReqStr = "/upload/drive/v2/files?fileId="+fileId+"&uploadType=multipart";
    }
    
    gapi.client.request({
        'path': ReqStr,
        'method': 'PUT',
        'params': {'fileId': fileId, 'convert':'true', 'uploadType': 'multipart'},
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
	   path: "/drive/v2/files/"+fileId+"?fields=exportLinks%2Cid%2Ctitle%2Cparents"
	});
	request.execute(function(resp) {
	    downloadFile(resp, callback);

	});

	return;
  
}




function downloadFile(file, callback) {
	if (file.exportLinks) {
	   var accessToken = gapi.auth.getToken().access_token;
           show_block_div();
          
           $.ajax({
                        type: "GET",
                        url: "/command/google_proxy/"+accessToken+"/?url=" + encodeURIComponent( file.exportLinks['text/plain'] ),
                        success:  function(Data) {
                                    callback(Data, file);
                                },
                        error: default_alert
                     }
                  );
          
          
	} else {
	  my_alert("There is some error during download meta info")
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