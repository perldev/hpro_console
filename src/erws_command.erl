-module(erws_command).


-import(lists, [foldl/3,foreach/2]).

-include("erws_console.hrl").
-include("deps/eprolog/include/prolog.hrl").

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
    {ok, Req, undefined}
.
    
terminate(_Req, _State, _Reason) ->
    ok.
 

    
% Should never get here.
handle(Req, State) ->
     { Path, Req1} = cowboy_req:path_info(Req),
     ?CONSOLE_LOG("Unexpected request: ~p~n", [Path]),
%      {Username, Password, Req2} = credentials(Req1),
     {ok, NewReq} = echo(Path, Req, State),
%       case {Username, Password} of
%             {?USERNAME, ?PASSWORD} ->
%                  echo(my_join(Path), Req2, State);
%             _ ->
%                 unauthorized(Req2)
%       end,    
      { ok,NewReq,State}
      
.


 


 
echo([<<"reload">>], Req, State)->
	  prolog:delete_inner_structs(),
	  ?INCLUDE_HBASE(""),    
	  echo([<<"show_code">>], Req, State)
; 
echo([<<"upload_code">>, Session], Req, _State)->
	   Got = cowboy_req:body_qs(Req),
	   SessKey = binary_to_list(Session),
	   ?CONSOLE_LOG("~p code here ~p ~n",[?LINE,Got]),
	   {ok, PostVals, Req2}  = Got, 
	   Code = proplists:get_value(<<"code">>, PostVals),
	   NewBinary = binary:replace(Code,[<<"\n">>,<<"\t">>],<<"">>, [ global ] ),
	   CodeList = binary:split(NewBinary, [<<".">>],[global]),
           ?CONSOLE_LOG("~p code chuncks ~p ~n",[?LINE,CodeList]),
           [ {SessKey, _Pid, _Pid2, NameSpace } ] = ets:lookup(?ERWS_LINK, SessKey),
           
	   ResDelete = ( catch prolog:delete_structs( NameSpace ) ),
	   ?CONSOLE_LOG("~p delete prev database ~p ~n",[?LINE,{NameSpace, ResDelete}]),
	   ResCreate = (catch prolog:create_inner_structs( NameSpace )),
	   ?CONSOLE_LOG("~p create prev database ~p ~n",[?LINE,{NameSpace, ResCreate}]),
	   Res = compile_foldl(CodeList, NameSpace),
           ?CONSOLE_LOG("~p code here ~p ~n",[?LINE,Code]),
    	   cowboy_req:reply(200, [{<<"Content-Type">>, <<"text/html">>}],
					Res, Req2)
    
;
echo([<<"show_code">>], Req, _State)->
	   ResBin = prolog_shell:get_code_memory_html(),		  
    	   cowboy_req:reply(200, [{<<"Content-Type">>, <<"text/html">>}],
					ResBin, Req)
    
;
echo([<<"plain_code">>], Req, _State)->
	   ResBin = prolog_shell:get_code_memory(),		  
    	   cowboy_req:reply(200, [{<<"Content-Type">>, <<"text/plain">>}],
					ResBin, Req)
    
;

echo(Path1, Req, _State)->
	  Path = "static/index.html",	
          ?CONSOLE_LOG("~p try to find file ~p",[?LINE,Path]),
          Type = mochiweb_mime:from_extension(filename:extension( Path ) ),
    	  case file(Path) of
		{error,_} ->
		        cowboy_req:reply(200, [{<<"Content-Type">>, <<"text/html">>}],
                <<"<html><head><title>may be i m working</title></head></html>">>,Req);
               Val -> 		
          		?CONSOLE_LOG("~p  find file ~p ~n",[?LINE, Type ]),
         		cowboy_req:reply(200, [{<<"Content-Type">>, Type }], Val, Req)
	 end.
	
file(Fname) ->
            case file:open(Fname, [read, raw, binary]) of
		{ok, Fd} ->
		    scan_file(Fd, <<>>, file:read(Fd, 1024));
		{error, Reason} ->
		    {error, Reason}
            end.

scan_file(Fd, Occurs, {ok, Binary}) ->
    scan_file(Fd, <<Occurs/binary, Binary/binary>>, file:read(Fd, 1024));
scan_file(Fd, Occurs, eof) ->
    file:close(Fd),
    Occurs;
scan_file(Fd, _Occurs, {error, Reason}) ->
    file:close(Fd),
    {error, Reason}.
  
  
compile_foldl([Head|Tail], Prefix )->
    Res = compile_patterns(Head),
    compile_foldl(Tail,[ Res ], Res, Prefix)
.
%TODO mistakes to web console
compile_foldl(_,_, Res = {error, _}, Prefix )->
    io_lib:format("~p ~n",[Res])
;
%%there Head will be true see compile_patterns bellow
compile_foldl([  ], [Head | ListRes], _, Prefix)->
      Fun = fun( { ok, Term }, Prefix )->
		prolog:process_term(Term, Prefix)
	    end,
     Terms  = lists:reverse(ListRes),
     lists:foldl(Fun, Prefix, Terms ),
     "yes"
;

compile_foldl([Head| Tail], ListRes ,_Res, Prefix )->
     Res = compile_patterns(Head),
     ?CONSOLE_LOG("~p  got term ~p ~n",[?LINE, Res ]),
     compile_foldl(Tail, [ Res| ListRes ], Res, Prefix)
.


compile_patterns(<<>>)->
    true
;
compile_patterns( OnePattern)->
%       #%# hack for numbers
      NewBinary = binary:replace(OnePattern,[<<"#%#">>],<<".">>, [ global ] ),
      HackNormalPattern =  <<NewBinary/binary, " . ">>,
      ?CONSOLE_LOG("~p begin process one pattern   ~p ~n",[ {?MODULE,?LINE}, HackNormalPattern ] ),
      {ok, Terms , L1} = erlog_scan:string( binary_to_list(HackNormalPattern) ),
      erlog_parse:term(Terms)
.



	   
	   
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
	   
	   
	   

