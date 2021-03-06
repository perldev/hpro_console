-module(erws_command).

-include("erws_console.hrl").
-include_lib("eprolog/include/prolog.hrl").

-compile(export_all).

% Behaviour cowboy_http_handler
-export([init/3, handle/2, terminate/3]).

% Behaviour cowboy_http_websocket_handler



% Called to know how to dispatch a new connection.
init({tcp, http}, Req, _Opts) ->
    { Path, Req3} = cowboy_req:path_info(Req),
    io:format("Request: ~p ~n", [ {Req,Path} ]),

    % "upgrade" every request to websocket,
    % we're not interested in serving any other content.
    {ok, Req3, undefined}
.
    
terminate(_Req, _State, _Reason) ->
    ok.

headers_text_plain() ->
        [ {<<"access-control-allow-origin">>, <<"*">>},  {<<"Content-Type">>, <<"text/plain">>} ].
        
headers_text_html() ->
        [ {<<"access-control-allow-origin">>, <<"*">>},  {<<"Content-Type">>, <<"text/html">>}  ].      

headers_json_plain() ->
        [ {<<"access-control-allow-origin">>, <<"*">>},  {<<"Content-Type">>, <<"application/json">>} ].
        
% Should never get here.
handle(Req, State) ->
     { Path, Req1} = cowboy_req:path_info(Req),
     ?CONSOLE_LOG("Unexpected request: ~p~n", [Path]),
%      {Username, Password, Req2} = credentials(Req1),
      Res =  ( catch echo(Path, Req, State) ),
      ?CONSOLE_LOG("got request: ~p~n", [Res]),
      {ok, NewReq} = Res,      
      { ok,NewReq,State}.
      
generate_api_url(Page) ->
    "http://codeide.com/prolog/auth/"++Page
.
generate_page_url(Page) ->
    "http://codeide.com/index.html?public_key=" ++ Page
.

key_list2dict(List) ->
    lists:foldl(fun( {Key, Value}, Dict ) ->
                     dict:store(Key, Value, Dict)
                end,  dict:new(), List).

process_ip_perm({ {N1, N2, N3,  N4},  Perm }) ->
    Ip = lists:flatten( io_lib:format("~p.~p.~p.~p",[N1,N2,N3,N4]) ),
    key_list2dict([{ip, Ip},{perm, Perm} ])
;
process_ip_perm( { All, Perm } )->
        key_list2dict([{ip, All},{perm, Perm} ])
.

get_namespace_info(Record)->
         NameSpace = erlang:element(4, Record),
         Name = erlang:element(2, Record),
        {NameSpace, _GoogleFolder, Config}  = api_auth_demon:get_name_space_info(NameSpace),
        {ok, ListPerms} = dict:find(ips, Config),
        Desc =  case  dict:find(description, Config) of    
                    error-><<>>;
                    {ok, Value}-> Value
                end,
         Salt = case  dict:find(salt, Config) of    
                    error-><<>>;
                    {ok, Value1}-> list_to_binary( Value1 )
                end,
         ProcPermList = lists:map(fun process_ip_perm/1, ListPerms),
        
         {ok, IoList}= tmpl_managing_panel:render([
                      {name, Name},
                      {id, NameSpace},
                      {salt, Salt},
                      {description, Desc},
                      {permissions, ProcPermList},
                      {public_url,generate_page_url(NameSpace) },
                      {public_api_urls,generate_api_url(NameSpace) }
                     ]),          
         lists:flatten(IoList)
          


.

get_list_namespaces(UserId)->
    List = ets:lookup(?ETS_REG_USERS, UserId ),
    case List of
            [] ->
                 jsx:encode([]);
            _L ->
                 NameSpaceName = lists:map(fun(E)->   { UserId, Name, Id, _PublicId } = E, {Id, Name } end, List),
                 jsx:encode(NameSpaceName)
    end
.

get_list_namespaces_public(UserId)->
    List = ets:lookup(?ETS_REG_USERS, UserId ),
    case List of
            [] ->
                 jsx:encode([]);
            _L ->
                 NameSpaceName = lists:map(fun(E)->   { UserId, Name, _Id, PublicId } = E, {list_to_binary(PublicId), Name } end, List),
                 jsx:encode(NameSpaceName)
    end
.


echo([<<"google_proxy">>, Session ], Req, State)->
         
         SessKey = binary_to_list(Session),
         [{SessKey, _UserId }]  = ets:lookup(?AUTH_SESSION, SessKey ),
        
        {Url, Req2} = cowboy_req:qs_val(<<"url">>, Req),
        ?CONSOLE_LOG("~p go to the  ~p ~n",[?LINE, Url]),

        Text  = google_api:google_download_request( binary_to_list(Url), SessKey ),
        cowboy_req:reply(200, headers_text_plain(),
                                        Text, Req2)
;

echo([<<"list_namespace">>, Session ], Req, State)->

     SessKey = binary_to_list(Session),
     [ {_,  UserId} ] = ets:lookup(?AUTH_SESSION, SessKey),
     NameSpaces  = get_list_namespaces(UserId),
     ?CONSOLE_LOG("~p list of namespaces ~p ~n",[?LINE,NameSpaces]),
     cowboy_req:reply(200, headers_json_plain(),
                                        NameSpaces, Req)
;
echo( [ <<"find_workspace">>, Session ], Req, State)->

     SessKey = binary_to_list(Session),
     [ {_,  UserId} ] = ets:lookup(?AUTH_SESSION, SessKey),
     WorkSpace  =      google_api:google_get_user_workspace(SessKey, UserId), 
     %%TODO process exception
     ?CONSOLE_LOG("~p find workspace ~p ~n",[?LINE,WorkSpace]),
     cowboy_req:reply(200, headers_text_plain(),
                                        WorkSpace, Req)
    

;
echo( [<<"update_salt">>, Session, NameSpaceB ], Req, State)->
      NameSpace = binary_to_list(NameSpaceB),
      SessKey = binary_to_list(Session),
      [ { SessKey, UserId }]  = ets:lookup(?AUTH_SESSION, SessKey ),
      Got = cowboy_req:body_qs(?MAX_UPLOAD, Req),
      {ok, PostVals, Req2}  = Got, 
      Value = proplists:get_value(<<"salt">>, PostVals),
      List = ets:lookup(?ETS_REG_USERS, UserId ),      
      case  lists:keysearch(NameSpace, 4, List) of
                        {value, Record } -> 
                                case Value of
                                     <<>> ->
                                            ?CONSOLE_LOG("~p delete salt  ~p ~n",[?LINE, NameSpace]),
                                            api_auth_demon:delete_config(NameSpace, salt);
                                      _ ->  
                                            ?CONSOLE_LOG("~p adding  salt  ~p ~n",[?LINE, NameSpace]),
                                            api_auth_demon:update_config(NameSpace, salt, binary_to_list(Value) )
                                end,
                                cowboy_req:reply(200, headers_text_html(),
                                                                    <<"ok">>, Req2);
                         _->
                                cowboy_req:reply(500, headers_text_plain(),
                                                                    <<"not_found">>, Req2)
                         
     end
;
echo( [<<"update_desc">>, Session, NameSpaceB ], Req, State)->
      NameSpace = binary_to_list(NameSpaceB),
      SessKey = binary_to_list(Session),
      [ { SessKey, UserId }]  = ets:lookup(?AUTH_SESSION, SessKey ),
      Got = cowboy_req:body_qs(?MAX_UPLOAD, Req),
      {ok, PostVals, Req2}  = Got, 
      Value = proplists:get_value(<<"description">>, PostVals),
      List = ets:lookup(?ETS_REG_USERS, UserId ),      
      case  lists:keysearch(NameSpace, 4, List) of
                        {value, Record } -> 
                                api_auth_demon:update_config(NameSpace, description, Value),
                                cowboy_req:reply(200, headers_text_html(),
                                                                    <<"ok">>, Req2);
                         _->
                                cowboy_req:reply(500, headers_text_plain(),
                                                                    <<"not_found">>, Req2)
                         
     end
;
echo( [ <<"get_expert_info">>, Session, NameSpaceB ], Req, State)->
     NameSpace = binary_to_list(NameSpaceB),
     SessKey = binary_to_list(Session),
     %%TODO process exception
     [{SessKey, UserId }]  = ets:lookup(?AUTH_SESSION, SessKey ),
     List = ets:lookup(?ETS_REG_USERS, UserId ),
     case  lists:keysearch(NameSpace, 4, List) of
                        {value, Record } -> 
                                ?CONSOLE_LOG("~p find userid ~p ~n",[?LINE,UserId]),
                                ?CONSOLE_LOG("~p get info from namespace ~p ~n",[?LINE,NameSpace]),

                                HtmlText  = get_namespace_info(Record),
                                cowboy_req:reply(200, headers_text_html(),
                                                                    HtmlText, Req);
                         _->
                            cowboy_req:reply(200, headers_text_plain(),
                                                                    <<"nothing">>, Req)
                         
    end
    

;
echo( [ <<"create_managing_command_session">>, Session ], Req, State)->

     SessKey = binary_to_list(Session),
     UserId =      google_api:google_get_user_id(SessKey), 
     %%TODO process exception
     ets:insert(?AUTH_SESSION, {SessKey, UserId } ),
     ?CONSOLE_LOG("~p find workspace ~p ~n",[?LINE,UserId]),
     NameSpaces  = get_list_namespaces_public(UserId),
     ?CONSOLE_LOG("~p list of namespaces ~p ~n",[?LINE,NameSpaces]),
     cowboy_req:reply(200, headers_json_plain(),
                                        NameSpaces, Req)
    

;

echo( [ <<"create_command_session">>, Session ], Req, State)->

     SessKey = binary_to_list(Session),
     UserId =  google_api:google_get_user_id(SessKey), 
     %%TODO process exception
     ets:insert(?AUTH_SESSION, {SessKey, UserId } ),
     NameSpaces  = get_list_namespaces(UserId),
     
     ?CONSOLE_LOG("~p list of namespaces ~p ~n",[?LINE,NameSpaces]),
     cowboy_req:reply(200, headers_json_plain(),
                                        NameSpaces, Req)
    

;
%%there is a permissions bug problem
echo( [ <<"save_public">>, AuthSession, BName, ForeinId ], Req, State )->
          SessKey = binary_to_list(AuthSession),
          Got = cowboy_req:body_qs(?MAX_UPLOAD, Req),
          LForeign = binary_to_list(ForeinId),
          ?CONSOLE_LOG("~p code here ~p ~n",[?LINE,Got]),
          {ok, PostVals, Req2}  = Got, 
          BCode = proplists:get_value(<<"code">>, PostVals),
          Code = <<BCode/binary,"\n">>,
          [ {_,  UserId} ] = ets:lookup(?AUTH_SESSION, SessKey),
          List = ets:lookup(?ETS_REG_USERS, UserId ),
          Result = case  lists:keysearch(ForeinId, 3, List) of
                        {value, Record } -> 
                                Id = erlang:element(4, Record), 
                                EtsTable = common:get_logical_name(Id, ?RULES),    
                                File = tmp_export_file(),
                                file:write_file(File, Code),                                
                                case catch  prolog:compile( Id, File, 0 ) of
                        	    ok ->
	                                api_auth_demon:save_public_system(Id, LForeign, EtsTable ),
	                                <<"yes">>;
	                            Re -> 
                                        ?CONSOLE_LOG("~p ERROR load code  ~p ~n",[{?MODULE,?LINE},Re]),
                                        list_to_binary(Re)    
	                        end;                          
                        false ->
                                <<"not_found">>
                   end,     
          cowboy_req:reply(200, headers_text_plain() ,
                                        Result, Req2)
; 
%%there is a permissions bug problem
echo( [ <<"make_public">>, AuthSession, BName, ForeinId ], Req, State )->

          SessKey = binary_to_list(AuthSession),
          Got = cowboy_req:body_qs(?MAX_UPLOAD, Req),
          ?CONSOLE_LOG("~p code here ~p ~n",[?LINE,Got]),
          {ok, PostVals, Req2}  = Got, 
          BCode = proplists:get_value(<<"code">>, PostVals),
          Code = <<BCode/binary,"\n">>,
          [ {_,  UserId} ] = ets:lookup(?AUTH_SESSION, SessKey),
          List = ets:tab2list(?ETS_REG_USERS ),
          ?CONSOLE_LOG("~p code here ~p ~n",[?LINE,List]),
          Result = check_workspace(List, UserId, ForeinId, BName, Code),
          cowboy_req:reply(200, headers_text_plain(),
                                        Result, Req2)
; 
% DEPRECATED
echo([<<"reload">>], Req, State)->
	  prolog:delete_inner_structs(),
	  ?INCLUDE_HBASE(""),    
	  echo([<<"show_code">>], Req, State)
; 
echo([<<"upload_code">>, Session], Req, _State)->
	   Got = cowboy_req:body_qs(?MAX_UPLOAD, Req),
	   SessKey = binary_to_list(Session),	   
	   {ok, PostVals, Req2}  = Got, 
	   BCode = proplists:get_value(<<"code">>, PostVals),
	   Code = <<BCode/binary,"\n">>,
	   File = tmp_export_file(),
	   file:write_file(File, Code),
	   [ {SessKey, _Pid, _Pid2, NameSpace } ] = ets:lookup(?ERWS_LINK, SessKey),
	   Res =  case catch prolog:compile(NameSpace, File) of
			ok -> <<"yes">>;
% 			 {badmatch,{error,{1,erlog_parse,{expected,')'}}}}
			Rsss  ={'EXIT', { Mistake, _Stack } }-> 
                                ?CONSOLE_LOG("~p ERROR load code  ~p ~n",[{?MODULE,?LINE}, Rsss]),
                                unicode:characters_to_list( io_lib:format("~p",[Mistake] ) )
		   end,
           ?CONSOLE_LOG("~p code here ~p ~n",[{?MODULE, ?LINE},{Res, Code}]),
    	   cowboy_req:reply(200, headers_text_html(),
					Res, Req2)
    
;
echo([<<"show_code">>], Req, _State)->
	   ResBin = prolog_shell:get_code_memory_html(),		  
    	   cowboy_req:reply(200, headers_text_html(),
					ResBin, Req)
    
;
echo([<<"plain_code">>], Req, _State)->
	   ResBin = prolog_shell:get_code_memory(),		  
    	   cowboy_req:reply(200, headers_text_plain(),
					ResBin, Req)
    
.


%%%TODO add checkin permission on google dir
check_workspace([], UserId, ForeinId, BName, Code)->
    Id = id_generator(),
    {ok, PATH_TO_SYSTEM} = application:get_env(erws, path_users_systems),
    ResCreate = (catch prolog:create_inner_structs( Id ) ),
    ?CONSOLE_LOG("~p create prev database ~p ~n",[?LINE,{Id, ResCreate}]),
    EtsTable = common:get_logical_name(Id, ?RULES),
    LForeign = binary_to_list(ForeinId),
    File = tmp_export_file(),
    file:write_file(File, Code),
    case prolog:compile(Id, File, 0) of
         ok ->
            ets:insert(?ETS_REG_USERS, { UserId,  BName, ForeinId, Id } ),
            api_auth_demon:regis_public_system( Id, LForeign, {file, PATH_TO_SYSTEM ++"/"++LForeign } ),
            api_auth_demon:save_public_system( Id, LForeign, EtsTable),
            <<"yes">>;
         Res->
            list_to_binary(Res)                 
    end;
check_workspace([Head | Tail], UserId, ForeinId, BName, Code)->          
                    case  Head of
                        { UserId, _Name, ForeinId, _ } -> <<"yes">>;
                        { _AnotherUserId, _SomeName, ForeinId, Prefix } ->                      
                            check_user_workspace(UserId, ForeinId, BName, Prefix);
                        _SomeAnother ->
                            check_workspace(Tail, UserId, ForeinId, BName, Code)
                   end
. 

check_user_workspace(UserId, ForeinId, BName, Prefix )->
    SubList = ets:lookup(?ETS_REG_USERS, UserId ),
    case   lists:keysearch(ForeinId, 3, SubList) of
        {value, _Record}->
                <<"yes">>;
        false->        
                ets:insert(?ETS_REG_USERS, { UserId,  BName, ForeinId, Prefix } ),
                <<"yes">>
    end
.  
  
  
% compile_foldl([Head|Tail], Prefix )->
%     Res = compile_patterns(Head),
%     compile_foldl(Tail,[ Res ], Res, Prefix, Head)
% .
% %TODO mistakes to web console
% compile_foldl(_,_, Res = {error, _}, Prefix, Prev )->
%     io_lib:format("~p - ~p ~n",[Res, Prev ])
% ;
% %%there Head will be true see compile_patterns bellow
% compile_foldl([  ], [Head | ListRes], _, Prefix, _Prev)->
%       Fun = fun( { ok, Term }, Prefix )->
%                  prolog:process_term(Term, Prefix)
% 	    end,
%      Terms  = lists:reverse(ListRes),
%      lists:foldl(Fun, {Prefix , 1 }, Terms ),
%      true
% ;
% 
% compile_foldl([Head| Tail], ListRes ,_Res, Prefix, _ )->
%      Res = compile_patterns(Head),
%      ?CONSOLE_LOG("~p  got term ~p ~n",[?LINE, Res ]),
%      compile_foldl(Tail, [ Res| ListRes ], Res, Prefix, Head)
% .
% 
% 
% compile_patterns(<<>>)->
%     true
% ;
% compile_patterns( OnePattern)->
% %       #%# hack for numbers
%       NewBinary1 = binary:replace(OnePattern,[<<"#%#">>],<<".">>, [ global ] ),
%       %% hack for =.. builtin predicate
%       NewBinary = binary:replace(NewBinary1,[<<"#%=#">>],<<"=..">>, [ global ] ),
%       HackNormalPattern =  <<NewBinary/binary, " . ">>,
%       ?CONSOLE_LOG("~p begin process one pattern   ~p ~n",[ {?MODULE,?LINE}, HackNormalPattern ] ),
%       {ok, Terms , L1} = erlog_scan:string( binary_to_list(HackNormalPattern) ),
%       erlog_parse:term(Terms)
% .

id_generator()->
    {T1,T2,T3 } = erlang:now(),  
    List =   lists:flatten( io_lib:format("~.B~.B~.B",[T1,T2,T3]) ) ,
    List
.

tmp_export_file()->
        Base = id_generator(),
        "/tmp/prolog_tmp_"++Base++".pl".
 
get_help()->
      <<"This is help...<br/>",
	"Use menu Online IDE above for load your own code to the memory <br/> ",
	"Terminal commands :<br/> ",
	"<strong>trace_on.</strong>  : turn on tracer under this terminal<br/> ",
	"<strong>trace_off.</strong>  : turn off tracer under this terminal<br/> ",
	"<strong>listing.</strong>  : show code  and facts availible in memory <br/> ",
	"<strong>yes.</strong>  : positive answer to questions of the system <br/> ",
	"<strong>no.</strong>  : negative answer to questions of the system <br/> ",
	"<strong>help.</strong>  : show this help<br/> "
      >>
      


.
	   
	   
	   

