-module(google_api).
-export([google_get_user_id/1, google_get_user_workspace/2, google_download_request/2  ]).
-include("erws_console.hrl").


google_download_request(Url, Session) ->
    case catch  httpc:request( get, { Url,
                                          [ 
                                            {"Authorization", "Bearer "++ Session},
                                            {"Content-Type","text/plain" },
                                            {"Accept","text/plain"}
                                          ] 
                                      },
                                          [ { connect_timeout,1000 },
                                            { timeout, 1000 }],
                                          [ { sync, true},
                                            { body_format, binary } 
                                          ] ) of
                          { ok, { {_NewVersion, 200, _NewReasonPhrase}, _NewHeaders, Text1 } } ->
                                  ?CONSOLE_LOG("~p got response from google ~p ~n",[ {?MODULE,?LINE}, {Text1, Url} ] ),
                                  Text1;
                          Res ->
                                  ?CONSOLE_LOG("~p got unexpected ~p ~n",[ {?MODULE,?LINE}, Res ] ),
                                   throw({google_auth_exception, Res})  %%TODO add count of fail and fail exception may be no
      end


.

google_get_user_id(Session) ->
    
%}     curl https://www.googleapis.com/oauth2/v1/userinfo?access_token=ya29.AHES6ZQBzuP3HKraZ8KOytJfAscUFfpPrkKkzK94N7EKgrMiDn2KKPP3
% {
%  "id": "108839122115636971602"
% }
      case catch  httpc:request( get, { "https://www.googleapis.com/oauth2/v1/userinfo?access_token="++Session,
                                          [ ] 
                                      },
                                          [ { connect_timeout,1000 },
                                            { timeout, 1000 }],
                                          [ { sync, true},
                                            { body_format, binary } 
                                          ] ) of
                          { ok, { {_NewVersion, 200, _NewReasonPhrase}, _NewHeaders, Text1 } } ->
                                  [{_Res, Key}] = jsx:decode(Text1),

                                  ?CONSOLE_LOG("~p got response from google ~p ~n",[ {?MODULE,?LINE}, {Text1, Key} ] ),
                                  binary_to_list(Key);
                          Res ->
                                  ?CONSOLE_LOG("~p got unexpected ~p ~n",[ {?MODULE,?LINE}, Res ] ),
                                   throw({google_auth_exception, Res})  %%TODO add count of fail and fail exception may be no
      end.
      
google_get_user_workspace(SessKey, UserId) ->
        case catch ets:lookup(?ETS_REG_USERS_WORKSPACES, UserId) of
                [ ] -> create_google_workspace(SessKey, UserId);
                [{UserId, WorkSpace} ] -> WorkSpace       
        end.
        
create_google_workspace(SessKey, UserId) ->

% {"title":"ProjectName1","mimeType":"application/vnd.google-apps.folder",
%"parents":[{"kind":"drive#parentReference","id":"0B-GDhU5T7c8ka0FoMDVaSlRWZEU","isRoot":false}]}
    Post = <<"{\"title\":\"PrologWorkSpace\",\"mimeType\":\"application/vnd.google-apps.folder\"}">>,
    case catch  httpc:request( post, { "https://www.googleapis.com/drive/v2/files/?alt=json",
                                          [
                                          {"Content-Length", integer_to_list( erlang:byte_size(Post) )},
                                          {"Content-Type","application/json" },
                                          {"Host", "www.googleapis.com" },
                                          {"Authorization", "Bearer "++ SessKey}
                                          ],
                                          "application/json",
                                          Post
                                          
                                      },
                                          [ { connect_timeout,1000 },
                                            { timeout, 1000 }],
                                          [ { sync, true},
                                            { body_format, binary } 
                                          ] ) of
                          { ok, { {_NewVersion, 200, _NewReasonPhrase}, _NewHeaders, Text1 } } ->                                  
                                  ?CONSOLE_LOG("~p got response from google ~p ~n",[ {?MODULE,?LINE}, Text1 ] ),
                                  List = jsx:decode(Text1),
                                  {value, { _, Id } }   = lists:keysearch(<<"id">>, 1, List),
                                  IdL = binary_to_list(Id),
                                  ets:insert(?ETS_REG_USERS_WORKSPACES,{UserId,IdL }),
                                  IdL;
                          Res ->
                                  ?CONSOLE_LOG("~p got unexpected ~p ~n",[ {?MODULE,?LINE}, Res ] ),
                                   throw({google_auth_exception, Res})  %%TODO add count of fail and fail exception may be no
      end
.

