-module(erws_command).


-import(lists, [foldl/3,foreach/2]).

-include("prolog.hrl").
-compile(export_all).

% Behaviour cowboy_http_handler
-export([init/3, handle/2, terminate/2]).

% Behaviour cowboy_http_websocket_handler



% Called to know how to dispatch a new connection.
init({tcp, http}, Req, _Opts) ->
    { Path, Req3} = cowboy_req:path_info(Req),
    io:format("Request: ~p ~n", [ {Req,Path} ]),

    % "upgrade" every request to websocket,
    % we're not interested in serving any other content.
    {ok, Req, undefined}
.
    
terminate(_Req, _State) ->
    ok.
 

    
% Should never get here.
handle(Req, State) ->
     { Path, Req1} = cowboy_req:path_info(Req),
     ?DEBUG("Unexpected request: ~p~n", [Path]),
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
	  ?INCLUDE_HBASE,    
	  echo([<<"show_code">>], Req, State)
; 
echo([<<"upload_code">>], Req, _State)->
	   Got = cowboy_req:body_qs(Req),
	   ?DEBUG("~p code here ~p ~n",[?LINE,Got]),
	   {ok, PostVals, Req2}  = Got, 
	   Code = proplists:get_value(<<"code">>, PostVals),
	   NewBinary = binary:replace(Code,[<<"\n">>,<<"\t">>],<<"">>, [ global ] ),
	   CodeList = binary:split(NewBinary, [<<".">>],[global]),
           ?DEBUG("~p code chuncks ~p ~n",[?LINE,CodeList]),
	   prolog:delete_inner_structs(),
	   Res = compile_foldl(CodeList),
           ?DEBUG("~p code here ~p ~n",[?LINE,Code]),
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
          ?DEBUG("~p try to find file ~p",[?LINE,Path]),
          Type = mochiweb_mime:from_extension(filename:extension( Path ) ),
    	  case file(Path) of
		{error,_} ->
		        cowboy_req:reply(200, [{<<"Content-Type">>, <<"text/html">>}],
                <<"<html><head><title>may be i m working</title></head></html>">>,Req);
               Val -> 		
          		?DEBUG("~p  find file ~p ~n",[?LINE, Type ]),
         		cowboy_req:reply(200, [{<<"Content-Type">>, Type }], Val, Req)
	 end


	 .

file(Fname) ->
            case file:open(Fname, [read, raw, binary]) of
		{ok, Fd} ->
		    scan_file(Fd, <<>>, file:read(Fd, 1024));
		{error, Reason} ->
		    {error, Reason}
            end.

scan_file(Fd, Occurs, {ok, Binary}) ->
    scan_file(Fd, <<Occurs/binary,Binary/binary>>, file:read(Fd, 1024));
scan_file(Fd, Occurs, eof) ->
    file:close(Fd),
    Occurs;
scan_file(Fd, _Occurs, {error, Reason}) ->
    file:close(Fd),
    {error, Reason}.
  
  
compile_foldl([Head|Tail] )->
    Res = compile_patterns(Head),
    compile_foldl(Tail,[ Res ], Res)
.
compile_foldl(_,_, Res = {error, _} )->
    io_lib:format("~p ~n",[Res])
;
%%there Head will be true see compile_patterns bellow
compile_foldl([  ], [Head | ListRes], _)->
      Fun = fun( { ok, Term } )->
		prolog:process_term(Term)
	    end,
     Terms  = lists:reverse(ListRes),
     lists:foreach(Fun, Terms ),
     "yes"
;

compile_foldl([Head| Tail], ListRes ,_Res )->
     Res = compile_patterns(Head),
     ?DEBUG("~p  got term ~p ~n",[?LINE, Res ]),
     compile_foldl(Tail, [ Res| ListRes ], Res)
.


compile_patterns(<<>>)->
    true
;
compile_patterns( OnePattern )->
%       #%# hack for numbers
      NewBinary = binary:replace(OnePattern,[<<"#%#">>],<<".">>, [ global ] ),
      HackNormalPattern =  <<NewBinary/binary, " . ">>,
      ?DEBUG("~p begin process one pattern   ~p ~n",[ {?MODULE,?LINE}, HackNormalPattern ] ),
      {ok, Terms , L1} = erlog_scan:string( binary_to_list(HackNormalPattern) ),
      erlog_parse:term(Terms)
.


start_shell_process(TreeEts)->
      process_flag(trap_exit, true),
      ets:new(TreeEts,[ public, set, named_table ] ),
      shell_loop(TreeEts, ?TRACE_OFF).

shell_loop(TreeEts, TraceStatus) ->
    %%REWRITE it like trace
    case ets:lookup(TreeEts, 'next') of 
	  [{next, NextPid}]->
	      ?DEBUG("~p wait answer from user ~p",[{?MODULE,?LINE} ,NextPid ]),
	      receive  
		  {some_code, Back, <<$y, _Some/binary >>, Trace}->
		        ?DEBUG("~p send yes to ~p",[{?MODULE,?LINE} ,NextPid ]),  
		        NextPid ! { next, self() },
		        TraceStatusNew  = wait_result(Back, TreeEts, TraceStatus),	
		        shell_loop(TreeEts, TraceStatusNew);
		  {some_code, Back, _, Trace}->
		        NextPid ! { finish, self() },
			TraceStatusNew = wait_result(Back, TreeEts, TraceStatus),
			shell_loop(TreeEts,TraceStatusNew )
	      end;
	  []->
	    ?DEBUG("~p wait new aim from user ~p",[{?MODULE,?LINE}, TreeEts ]),
	    receive 
		  {some_code, Back, Code, TracePid}->	  
			  ?DEBUG("~p wait new aim from user ~p",[{?MODULE,?LINE}, {self(),Code} ]),
 			  spawn(?MODULE, server_loop, [ Code, TreeEts, self(), TracePid, TraceStatus ] ),%%begin new aim
			  NewTraceStatus = wait_result(Back, TreeEts, TraceStatus),	 
			  shell_loop(TreeEts, NewTraceStatus)
	    end
    end
.

wait_result(Back, TreeEts, TraceStatus)->
	    ?DEBUG("~p wait  in ~p",[{?MODULE,?LINE} , self() ]),
	    NewTraceStatus=
		    receive 
			        {result, R , finish, BackPid } ->
				      Back ! {result, result(R) },
				      ets:delete_all_objects(TreeEts),
				      TraceStatus
				      ;
				{result, R , has_next, BackPid } ->
				      Back ! {result, result(R) },
				      ets:insert(TreeEts, {next, BackPid} ),
				      TraceStatus
				      ;
				{?TRACE_ON, finish }->
				      Back ! {result, <<"Trace on \n">> },
				      ?TRACE_ON
				      ;
				{?TRACE_OFF, finish }->
				      Back ! {result, <<"Trace off \n">> },
				      ?TRACE_OFF
				      ;
				      
				Unexpected ->
				        ?DEBUG("~p got  ~p",[{?MODULE,?LINE}, Unexpected ]),
				        NormalReason = result( Unexpected ),
					Back ! {result, <<"No,~n ", NormalReason/binary>>},
					ets:delete_all_objects(TreeEts),
					TraceStatus
   	   end,
   	   NewTraceStatus
.
result(R) when  is_binary(R) ->
    R;
result(R)  ->
  list_to_binary ( lists:flatten( io_lib:format("~p",[R]) ) ).
    

	   
	   
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
	   
	   
	   

%% A simple Prolog shell similar to a "normal" Prolog shell. It allows
%% user to enter goals, see resulting bindings and request next
%% solution.
server_loop(P0, TreeEts, WebPid, TracePid, TraceStatus) ->
    process_flag(trap_exit, true),
    ParseGoal = (catch web_parse_code(P0) ),  
    ?DEBUG(" get aim ~p",[ParseGoal]),
    {_,T,T1} = now(),
    GlobalTempAim = list_to_atom( atom_to_list(?TEMP_SHELL_AIM)++ integer_to_list(T) ++ integer_to_list(T1) ),
    MyResult = 
    case ParseGoal  of
	{ok,halt} ->  
	    WebPid ! { <<"No~n">>, finish };
	{ok,trace_on} ->  
		WebPid ! { ?TRACE_ON, finish }
      
	;	    
	{ok,trace_off} ->  
		WebPid ! { ?TRACE_OFF, finish }

      
	;
	{ok, listing} ->  
		WebPid ! {result, prolog_shell:get_code_memory_html() ,finish, self() }
      
	;
	{ok, help} ->  
		WebPid ! {result, get_help() ,finish, self() }
	;
	
% 	{ok,Files} when is_list(Files) -> % we dont need
% 		WebPid ! {result, <<"No~n">>, finish, self() };
	{ok, Goal = {':-',_,_ } } ->
		WebPid ! {result, <<"No, use online IDE for making rules ~n">>, finish, self() };
		
	{ok,Goal = {',', _Rule, _Body} } ->
	      io:fwrite("Goal complex: ~p~n", [Goal]),
	      {TempAim, Dict} = prolog_shell:make_temp_complex_aim(Goal, dict:new()), 
      	      prolog_trace:trace_on(TraceStatus, TreeEts, TracePid ),
	      ListVars  = dict:to_list(Dict),
	      TempAim1 = list_to_tuple([ GlobalTempAim  |lists:map(fun({ Normal, Temp})->  Temp  end, ListVars ) ]),
     	      NewGoal = list_to_tuple([ GlobalTempAim  |lists:map(fun({ Normal, Temp})->  Normal  end, ListVars ) ]),
     	      ProtoType = list_to_tuple( lists:map(fun({ Normal, Temp})->  Normal  end, ListVars )  ),   
              TempProto   =  lists:map(fun({ Normal, Temp})->  Temp  end, ListVars )  ,              
     	      ets:insert(?RULES,{GlobalTempAim, ProtoType, Goal }  ),     	      
	      ?DEBUG("TempAim : ~p~n", [{TempAim1, NewGoal, Goal } ]),
              StartTime = erlang:now(), 
	      BackPid = spawn_link(prolog, conv3, [list_to_tuple(TempProto), TempAim1,  dict:new(), erlang:self(), now() , TreeEts]),
	      prolog_shell:process_prove_erws(TempAim1, NewGoal, BackPid, WebPid, StartTime );       
% 	    shell_prove_result(P0({prove,Goal}));	
	{ok,Goal} when is_tuple(Goal)->
	      io:fwrite("Goal : ~p~n", [Goal]),
	      {TempAim, _ShellContext } = prolog_shell:make_temp_aim(Goal), 
	      prolog_trace:trace_on(TraceStatus, TreeEts, TracePid ),
	      ?DEBUG("TempAim : ~p~n", [TempAim]),
	      ?DEBUG("~p make temp aim ~p ~n",[ {?MODULE,?LINE}, TempAim]),
	      [_UName|Proto] = tuple_to_list(TempAim),
	      StartTime = erlang:now(),
	      BackPid = spawn_link(prolog, conv3, [list_to_tuple(Proto), TempAim,  dict:new(), 
						    erlang:self(), now() , TreeEts]),
	      prolog_shell:process_prove_erws(TempAim, Goal, BackPid, WebPid, StartTime );
% 	    shell_prove_result(P0({prove,Goal}));
        {ok,Goal} ->
		WebPid ! {result, <<"No, use online IDE for making rules ~n">>, finish, self() }
	;
	{error,P = {_, Em, E }} ->
	    ?DEBUG(" GOT FROM THER prolog ~p ~n",[P]),
	    NormalP = result(P),
	    WebPid ! {result, <<"No~n", NormalP/binary>>, finish, self() };
	Error ->
	    NormalP = result(Error),
	    ?DEBUG(" GOT FROM THER prolog ~p ~n",[Error]),
	    WebPid ! {result, <<"No unexpected symbol ~n">>, finish, self() }
    end,
    ?DEBUG(" delete temp ~p ~n",[TreeEts]),
    ets:delete(?RULES, GlobalTempAim )
.

web_parse_code(P0)->
    {ok, Terms , _L1} = erlog_scan:string( binary_to_list( P0 ) ),
    erlog_parse:term(Terms).

    
