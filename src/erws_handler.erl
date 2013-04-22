-module(erws_handler).


-import(lists, [foldl/3,foreach/2]).

-include("prolog.hrl").
-compile(export_all).

% Behaviour cowboy_http_handler
-export([init/3,  terminate/2]).

% Behaviour cowboy_http_websocket_handler
-behaviour(cowboy_websocket_handler).

-export([init/3]).
-export([websocket_init/3]).
-export([websocket_handle/3]).
-export([websocket_info/3]).
-export([websocket_terminate/3]).

% Called to know how to dispatch a new connection.
init({tcp, http}, Req, _Opts) ->

    % "upgrade" every request to websocket,
    % we're not interested in serving any other content.
    
    {upgrade, protocol, cowboy_websocket}.
    
terminate(_Req, _State) ->
    ok.
 


start_link_session([ <<"trace">>, Session],TreeEts)->
        PidTrace = spawn_link(?MODULE, start_trace_process, []),
        SessKey = binary_to_list(Session),
        [ {SessKey, Pid, ?UNDEF} ] = ets:lookup(?ERWS_LINK, SessKey),%%do not use one session
        ets:insert(?ERWS_LINK,{SessKey, Pid, PidTrace} ),     %%save all links  
        ets:insert(?ERWS_LINK,{Pid, PidTrace,'main', SessKey}  ),       
        ets:insert(?ERWS_LINK,{PidTrace, Pid,'trace', SessKey} ),    
	PidTrace;
	
start_link_session([ Session],TreeEts)->
        Pid = spawn_link(?MODULE, start_shell_process, [ TreeEts ]),
        SessKey = binary_to_list(Session),
        [  ] = ets:lookup(?ERWS_LINK, SessKey), %%do not use one session
        ets:insert(?ERWS_LINK,{SessKey, Pid, ?UNDEF} ),       
	Pid.
	
    
% Called for every new websocket connection.
websocket_init(Any, Req, []) ->
    ?DEBUG("~nNew client ~p",[Req]),

    {Key, Req1} = cowboy_req:header(<<"sec-websocket-key">>, Req),
    TreeEts = list_to_atom( binary_to_list( Key ) ),
    { Path, Req_} = cowboy_req:path_info(Req1) ,
    %TODO make key from server
    ?DEV_DEBUG("~n new session ~p",[ Path ]),
    Req2 = cowboy_req:compact(Req_),
    Pid = start_link_session(Path, TreeEts), 
    {ok, Req2, Pid , hibernate}.

% Called when a text message arrives.
websocket_handle({text, Msg}, Req, StatePid ) ->
    ?DEBUG("~p Received: ~p ~n ~p~n~n", [{?MODULE,?LINE},Msg, StatePid]),
    ?DEV_DEBUG(" Req: ~p ~n", [Req]),

     Res = process_req(StatePid, Msg),
    ?DEV_DEBUG("~p send back: ~p ~n", [{?MODULE,?LINE},{StatePid, Res}]),
    
    {reply,
        {text, Res },
        Req, StatePid, hibernate
    };

% With this callback we can handle other kind of
% messages, like binary.
websocket_handle(Any, Req, State) ->
    ?DEBUG("unexpected: ~p ~n ~p~n~n", [Any, State]),
    {ok, Req, State}.

% Other messages from the system are handled here.
websocket_info(_Info, Req, State) ->
    ?DEBUG("info: ~p ~n ~p~n~n", [Req, State]),
    {ok, Req, State, hibernate}.

websocket_terminate(Reason, Req, State) ->
    ?DEBUG("terminate: ~p ,~n ~p, ~n ~p~n~n", [Reason, Req, State]),
    delete_session(State),
    exit(State, normal),
    ok.
 
delete_session(StatePid)->
      case ets:lookup(?ERWS_LINK, StatePid) of
	  [ {StatePid, PidTrace,'main', SessKey} ]->
	      ets:delete(?ERWS_LINK, StatePid ),
	      ets:delete(?ERWS_LINK, SessKey ),
	      exit(StatePid, normal );
	  [ {StatePid, Pid,'trace', SessKey} ]->
		 ets:delete(?ERWS_LINK, StatePid ),
		 exit(StatePid, normal );
	  []->
		?LOG("~p exception ~p",[{?MODULE,?LINE},StatePid  ]),
		exit(bad)
      end
.
 
process_req(StatePid, Msg)->
%            ets:insert(?ERWS_LINK,{Pid, PidTrace,'main', SessKey}  ),       
%         ets:insert(?ERWS_LINK,{PidTrace, Pid,'trace', SessKey} ),    

      case ets:lookup(?ERWS_LINK, StatePid) of
	  [ {StatePid, PidTrace,'main', SessKey} ]->
		StatePid ! {some_code, erlang:self(), Msg, PidTrace},
		
		Res =  receive 
			  {result, Result} ->
			      Result
			end,
		PidTrace ! client_finish,
		?DEBUG("send back: ~p ~n ~p~n~n", [Res, StatePid]),
		 Res;
	  [ { StatePid, Pid, 'trace', SessKey} ]->
		  ?DEV_DEBUG("trace: ~p ~n ~p~n~n", [Msg, StatePid]),  
		  StatePid ! {binary_to_list(Msg), erlang:self() },
		  Res =  receive 
			      {result, finish} ->
				  <<"finish">>;
			      {result, Result} ->
				  Result
			  end,
		 ?DEBUG("send back: ~p ~n ~p~n~n", [Res, StatePid]),
		 Res;
	  []->
		?LOG("~p exception ~p",[{?MODULE,?LINE},StatePid  ]),
		exit(bad)
      end
.

start_trace_process()->
    trace_loop(wait_user, ?UNDEF ).


trace_loop(wait_user, ?UNDEF )->
    ?DEBUG(" tracer wait user next or finish: ~p ~n", [{?MODULE,?LINE}]),
    receive 
	{"next", Pid}-> %%first
	    trace_loop(wait_aim, Pid )
    end;       

trace_loop(wait_user, BackPid )->
   ?DEBUG("tracer wait user yes/no: ~p ~n", [{?MODULE,?LINE}]),
   
    receive 
	{Line, Pid}->
		 ?DEBUG("got from user: ~p ~n", [{?MODULE,?LINE,Line}]),
		  
		  case Line of
		      [$y,$e,$s| _ ] ->
			  BackPid ! next,
			  trace_loop(wait_aim, Pid );
		      _ ->
			 io:fwrite("finish job ~n"),
			 Pid ! {result, finish},
			 BackPid ! finish,
			 trace_loop(wait_aim, Pid )
		  end
		  
    end
;

trace_loop(wait_aim, Pid )->
	?LOG("~p tracer wait result of aim ~p ~n",[{?MODULE,?LINE}, Pid ]), 

	receive 
	    {debug_msg, BackPid, Index, Body } ->
    		  ?LOG("~p got debug  msg  ~p ~n",[{?MODULE,?LINE}, Body ]), 

		  Msg = io_lib:format("aim ~p call  ~p ? ~n yes or no~n  ", [Index, Body ] ),
		  Pid ! {result, Msg },
		  trace_loop(wait_user, BackPid )
	    ;
	    {res_msg, BackPid, Index, Body } ->
		  ?LOG("~p got res  msg  ~p ~n",[{?MODULE,?LINE}, Body ]), 

		  Msg = io_lib:format("aim ~p got  ~p ?  ~n  ", [Index ,Body ] ),
		  Pid ! {result, Msg },
		  trace_loop(wait_user, BackPid )
	    ;
	    finish->
		?LOG("~p got finish msg  ~n",[{?MODULE,?LINE} ]), 
		Pid ! {result, finish },
		trace_loop(wait_user, ?UNDEF );
	    client_finish ->
		?LOG("~p new trace wait  ~n",[{?MODULE,?LINE} ]), 
		Pid ! {result, finish },
		trace_loop(wait_user, ?UNDEF );
	    {Line, Pid}->
		?LOG("~p ignore msg from user  msg ~p ~n",[{?MODULE,?LINE}, Line ]), 
		trace_loop(wait_aim, Pid );
	    _Unexpected->
		?LOG("~p got unexpected msg ~p ~n",[{?MODULE,?LINE}, _Unexpected]), 
		Pid ! {result, <<"No\n">> },
		trace_loop(wait_user, ?UNDEF )
        end
.



  
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

    
