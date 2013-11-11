-module(erws_handler).


-import(lists, [foldl/3,foreach/2]).
-include("deps/eprolog/include/prolog.hrl").
-include("erws_console.hrl").

-compile(export_all).

% Behaviour cowboy_http_handler
-export([init/3,  terminate/2]).

% Behaviour cowboy_http_websocket_handler
-behaviour(cowboy_websocket_handler).

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
 
start_link_session([ <<"trace">>, Session])->        
        PidTrace = spawn(?MODULE, start_trace_process, []),
        SessKey = binary_to_list(Session),
        [ {SessKey, Pid, ?UNDEF, NameSpace} ] = ets:lookup(?ERWS_LINK, SessKey),%%do not use one session
        ets:insert(?ERWS_LINK,{SessKey, Pid, PidTrace, NameSpace} ),     %%save all links  
        ets:insert(?ERWS_LINK,{Pid, PidTrace,'main', SessKey}  ),       
        ets:insert(?ERWS_LINK,{PidTrace, Pid,'trace', SessKey} ),    
	PidTrace;
start_link_session([ <<"trace">>, Session, OutNameSpace])->
        OutNameSpaceL = binary_to_list(OutNameSpace),
        PidTrace = spawn(?MODULE, start_trace_process, [ ] ),
        SessKey = binary_to_list(Session),
        [ {SessKey, Pid, ?UNDEF, OutNameSpaceL} ] = ets:lookup(?ERWS_LINK, SessKey),%%do not use one session
        ets:insert(?ERWS_LINK,{SessKey, Pid, PidTrace, OutNameSpaceL} ),     %%save all links  
        ets:insert(?ERWS_LINK,{Pid, PidTrace,'main', SessKey}  ),       
        ets:insert(?ERWS_LINK,{PidTrace, Pid,'trace', SessKey} ),    
        PidTrace;	
start_link_session([ Session, OutNameSpace ]) ->
        %%TODO add changable namespace
        OutNameSpaceL = binary_to_list(OutNameSpace),
        
        Pid = spawn(?MODULE, start_shell_process, [ OutNameSpaceL, public ]),
        SessKey = binary_to_list(Session),
        [  ] = ets:lookup(?ERWS_LINK, SessKey), %%do not use one session
        ets:insert(?ERWS_LINK,{SessKey, Pid, ?UNDEF, OutNameSpaceL } ),       
        Pid;	
start_link_session([ Session])->
        %%TODO add changable namespace
        NameSpace =  auth_demon:get_free_namespace(),
        Pid = spawn(?MODULE, start_shell_process, [ NameSpace, temp ]),
        SessKey = binary_to_list(Session),
        [  ] = ets:lookup(?ERWS_LINK, SessKey), %%do not use one session
        ets:insert(?ERWS_LINK,{SessKey, Pid, ?UNDEF, NameSpace } ),       
	Pid.
	
    
% Called for every new websocket connection.
websocket_init(Any, Req, []) ->
    ?CONSOLE_LOG("~nNew client ~p",[Req]),
    %%HACK 
    { Path, Req_} = cowboy_req:path_info(Req) ,
    %TODO make key from server
    ?CONSOLE_LOG("~n new session ~p",[ Path ]),
    Req2 = cowboy_req:compact(Req_),
    Pid = start_link_session(Path), 
    {ok, Req2, Pid , hibernate}.

% Called when a text message arrives.
websocket_handle({text, Msg}, Req, StatePid ) ->
    ?CONSOLE_LOG("~p Received: ~p ~n ~p~n~n", [{?MODULE,?LINE},Msg, StatePid]),
    ?CONSOLE_LOG(" Req: ~p ~n", [Req]),
     Res = process_req(StatePid, Msg),
    ?CONSOLE_LOG("~p send back: ~p ~n", [{?MODULE,?LINE},{StatePid, Res}]),
    
    {reply,
        {text, Res },
        Req, StatePid,
        hibernate
    };

% With this callback we can handle other kind of
% messages, like binary.
websocket_handle(Any, Req, State) ->
    ?CONSOLE_LOG("unexpected: ~p ~n ~p~n~n", [Any, State]),
    {ok, Req, State}.

% Other messages from the system are handled here.
websocket_info(_Info, Req, State) ->
    ?CONSOLE_LOG("info: ~p ~n ~p~n~n", [Req, State]),
    {ok, Req, State, hibernate}.

websocket_terminate(Reason, Req, State) ->
    ?CONSOLE_LOG("terminate: ~p ,~n ~p, ~n ~p~n~n", [Reason, Req, State]),
    delete_session(State),
    ok.
 
delete_session(StatePid)->
      case ets:lookup(?ERWS_LINK, StatePid) of
	  [ {StatePid, PidTrace,'main', SessKey} ]->
		  
		  ets:delete(?ERWS_LINK, StatePid ),
		  [ {_, _, _, NameSpace}  ] = ets:lookup(?ERWS_LINK, SessKey),
		  ets:delete(?ERWS_LINK, SessKey ),		  
                  exit(PidTrace, kill ),
		  exit(StatePid, kill );
		  
	  [ {StatePid, Pid,'trace', SessKey} ]->
	  
		  ets:delete(?ERWS_LINK, StatePid ),
		  exit(Pid, kill ),
		  exit(StatePid, kill );
	  []->
		  ?CONSOLE_LOG("~p exception ~p",[{?MODULE,?LINE},StatePid  ]),
		  exit(bad)
      end
.
 
process_req(StatePid, Msg)->
      case ets:lookup(?ERWS_LINK, StatePid) of
	  [ {StatePid, PidTrace,'main', SessKey} ]->
		StatePid ! {some_code, erlang:self(), Msg, PidTrace},
		Res =   receive 
			    {result, get_char} ->
				    <<"get_char">>
				    ; 
			    {result, read} ->
				    <<"read_term">>
				    ;
			    {result, write, Something} ->
				    Something
				    ;	    
			    {result, Result} ->
				    PidTrace ! client_finish, 
				    Result
			end,
		 ?CONSOLE_LOG("send back: ~p ~n ~p~n~n", [Res, StatePid]),
		 Res;
	  [ { StatePid, Pid, 'trace', SessKey} ]->
		  ?CONSOLE_LOG("trace: ~p ~n ~p~n~n", [Msg, StatePid]),  
		  StatePid ! {binary_to_list(Msg), erlang:self() },
		  Res =  receive 
			      {result, finish} ->
				    <<"finish">>;
			      {result, Result} ->
				  Result
			  end,
		 ?CONSOLE_LOG("send back: ~p ~n ~p~n~n", [Res, StatePid]),
		 Res;
	  []->
		?CONSOLE_LOG("~p exception ~p",[{?MODULE,?LINE},StatePid  ]),
		exit(bad)
      end
.

start_trace_process()->
    trace_loop(wait_user, ?UNDEF ).


trace_loop(wait_user, ?UNDEF )->
    ?CONSOLE_LOG(" tracer wait user next or finish: ~p ~n", [{?MODULE,?LINE}]),
    receive 
	{"next", Pid}-> %%first
	    trace_loop(wait_aim, Pid )
    end;       

trace_loop(wait_user, BackPid )->
   ?CONSOLE_LOG("tracer wait user yes/no: ~p ~n", [{?MODULE,?LINE}]),
   receive 
	{Line, Pid}->
		  ?CONSOLE_LOG("got from user: ~p ~n", [{?MODULE,?LINE,Line}]),
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
	?CONSOLE_LOG("~p tracer wait result of aim ~p ~n",[{?MODULE,?LINE}, Pid ]), 

	receive 
	    {debug_msg, BackPid, Index, Body } ->
    		  ?CONSOLE_LOG("~p got debug  msg  ~p ~n",[{?MODULE,?LINE}, Body ]), 
		  Msg = io_lib:format("aim ~p call  ~p ? ~n yes or no~n  ", [Index, Body ] ),
		  Pid ! {result, Msg },
		  trace_loop(wait_user, BackPid )
	    ;
	    {res_msg, BackPid, Index, Body } ->
		  ?CONSOLE_LOG("~p got res  msg  ~p ~n",[{?MODULE,?LINE}, Body ]), 
		  Msg = io_lib:format("aim ~p got  ~p ?  ~n  ", [Index ,Body ] ),
		  Pid ! {result, Msg },
		  trace_loop(wait_user, BackPid )
	    ;
	    finish ->
		 ?CONSOLE_LOG("~p got finish msg  ~n",[{?MODULE,?LINE} ]), 
		 Pid ! {result, finish },
		 trace_loop(wait_user, ?UNDEF );
	    client_finish ->
		 ?CONSOLE_LOG("~p new trace wait  ~n",[{?MODULE,?LINE} ]), 
		 Pid ! {result, finish },
		 trace_loop(wait_user, ?UNDEF );
	    {Line, Pid} ->
		 ?CONSOLE_LOG("~p ignore msg from user  msg ~p ~n",[{?MODULE,?LINE}, Line ]), 
		 trace_loop(wait_aim, Pid );
	    Unexpected ->
		 ?CONSOLE_LOG("~p got unexpected msg ~p ~n",[{?MODULE,?LINE}, Unexpected]), 
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
     ?CONSOLE_LOG("~p  got term ~p ~n",[?LINE, Res ]),
     compile_foldl(Tail, [ Res| ListRes ], Res)
.


compile_patterns(<<>>)->
    true
;
compile_patterns( OnePattern )->
%       #%# hack for numbers with dot
      NewBinary = binary:replace(OnePattern,[<<"#%#">>],<<".">>, [ global ] ),
      HackNormalPattern =  <<NewBinary/binary, " . ">>,
      ?CONSOLE_LOG("~p begin process one pattern   ~p ~n",[ {?MODULE,?LINE}, HackNormalPattern ] ),
      {ok, Terms , L1} = erlog_scan:string( binary_to_list(HackNormalPattern) ),
      erlog_parse:term(Terms)
.

start_shell_process( Prefix, public)->
      TreeEts = ets:new(some,[ public, set, { keypos, 2 } ] ),
      IsHbase =   api_auth_demon:get_source(Prefix),
      ets:insert(TreeEts, {system_record, hbase, IsHbase}),
      shell_loop(TreeEts, ?TRACE_OFF, Prefix);
start_shell_process( Prefix, temp)->
      Pid = erlang:whereis(auth_demon), 
      prolog_shell:api_start_anon(Prefix, {heir, Pid} ),
      TreeEts = ets:new(some,[ public, set, { keypos, 2 } ] ),
      shell_loop(TreeEts, ?TRACE_OFF, Prefix).

shell_loop(TreeEts, TraceStatus, Prefix) ->
    %%REWRITE it like trace
    ets:insert(TreeEts, {system_record,?PREFIX, Prefix}),
    ?CONSOLE_LOG("~p working with  namespace ~p",[{?MODULE,?LINE} ,Prefix ]),
    case ets:lookup(TreeEts, 'next') of 
	  [{  NextPid, next,  Type }]->
	      ?CONSOLE_LOG("~p wait answer from user ~p",[{?MODULE,?LINE} ,NextPid ]),
	      ets:delete(TreeEts, 'next'),
	      TraceStatusNew =  wait_user_input(Type, TraceStatus, TreeEts, NextPid),
	      shell_loop(TreeEts, TraceStatusNew, check_namespace(TreeEts) );
	  []-> %%if we wait new aim
	    ?CONSOLE_LOG("~p wait new aim from user ~p",[{?MODULE,?LINE}, TreeEts ]),
	    receive 
		  {some_code, Back, Code, TracePid}->	  
			  ?CONSOLE_LOG("~p wait new aim from user ~p",[ {?MODULE,?LINE},Code ]),
			  common:regis_io_server( TreeEts, self() ),
 			  spawn(?MODULE, server_loop, [ Code, TreeEts, self(), TracePid, TraceStatus ] ),%%begin new aim
			  NewTraceStatus = wait_result(Back, TreeEts, TraceStatus),
			  shell_loop(TreeEts, NewTraceStatus, check_namespace(TreeEts))
	    end
    end
.
%%%if call use_namespace predicate
%%TODO make it safier
check_namespace(TreeEts)->
    [{system_record,?PREFIX, Prefix}] = ets:lookup(TreeEts, ?PREFIX),Prefix
.

%%it's like finite state machine
%%standard answer to prolog console
wait_user_input(wait, TraceStatus, TreeEts, NextPid)->
	      receive  
		  { some_code, Back, <<$y, _Some/binary >>, _Trace}->
		        ?CONSOLE_LOG("~p send yes to ~p",[{?MODULE,?LINE}, NextPid ]),  
		        NextPid ! { next, self() },
		        wait_result(Back, TreeEts, TraceStatus);
		  { some_code, Back, _, _Trace}->
		        NextPid ! { finish, self() },
			wait_result(Back, TreeEts, TraceStatus)
	      end
;
%%get char meta predicate to  prolog console
wait_user_input(get_char, TraceStatus, TreeEts, NextPid)->
	      receive  
		  { some_code, Back, Some, Trace}->
		        ?CONSOLE_LOG("~p send ~p to ~p",[{?MODULE,?LINE}, Some, NextPid ]),  
		        NextPid ! { char, Some },
		        wait_result(Back, TreeEts, TraceStatus);
		  R ->
		       ?CONSOLE_LOG("~p unxpected ~p ",[{?MODULE,?LINE}, R ]),  
			TraceStatus
	      end
;
%%read meta predicate to  prolog console
wait_user_input(read, TraceStatus, TreeEts, NextPid)->
	      receive  
		  { some_code, Back, Some, Trace } ->
		        ?CONSOLE_LOG("~p send ~p to ~p",[{?MODULE,?LINE}, Some, NextPid ]),  
		        NextPid ! { read, <<Some/binary," ">> },
		        wait_result(Back, TreeEts, TraceStatus);
		    R ->
		       ?CONSOLE_LOG("~p unxpected ~p ",[{?MODULE,?LINE}, R ]),  
			TraceStatus
	      end
.



wait_result(Back, TreeEts, TraceStatus)->
	    ?CONSOLE_LOG("~p wait  in ~p",[{?MODULE,?LINE} , self() ]),
	    %%%there will be  commands for web console input command
	    
	    NewTraceStatus= 
		    receive 
			        {result, R , finish, BackPid } ->
				      Back ! {result, result(R) },
				      TraceStatus
				      ;
				{result, R , has_next, BackPid } ->
				      Back ! {result, result(R) },
				      ets:insert(TreeEts, { BackPid, next, wait} ),
				      TraceStatus
				      ; 
				{result,  write, Something } ->
				      ?CONSOLE_LOG("~p write predicate  ~p to ~n",[{?MODULE,?LINE}, Something ]),
				      Binary = unicode:characters_to_binary(Something),
				      Back ! {result, write, <<"prolog_write,",Binary/binary >>  },
				      wait_write_ping(),
				      wait_result(Back, TreeEts, TraceStatus)
				      ;  
				{result,  get_char, BackPid } ->
				      Back ! {result, get_char },
				      ets:insert(TreeEts, {BackPid, next,   get_char} ),
				      TraceStatus
				      ;
     				{result, read, BackPid } ->
				      Back ! {result, read },
				      ets:insert(TreeEts, {BackPid, next,   read} ),
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
				        ?CONSOLE_LOG("~p got  ~p",[{?MODULE,?LINE}, Unexpected ]),
				        NormalReason = result( Unexpected ),
					Back ! {result, <<"No,~n ", NormalReason/binary>>},
					TraceStatus
   	   end,
   	   NewTraceStatus
.
result(R) when  is_binary(R) ->
    R;
result(R)  ->
  list_to_binary ( lists:flatten( io_lib:format("~p",[R]) ) ).
  
wait_write_ping()->    
    receive 
       {some_code, _Back, Code, _TracePid}->
	       ?CONSOLE_LOG("~p write pong  ~p",[{?MODULE,?LINE}, Code ]),
		next
    end

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
	   
	   
	   

%% A simple Prolog shell similar to a "normal" Prolog shell. It allows
%% user to enter goals, see resulting bindings and request next
%% solution.
server_loop(P0, TreeEts, WebPid, TracePid, TraceStatus) ->
    process_flag(trap_exit, true),
    put( ?DYNAMIC_STRUCTS, common:get_logical_name(TreeEts, ?DYNAMIC_STRUCTS) ),

    ParseGoal = (catch web_parse_code(P0) ),  
    ?CONSOLE_LOG(" get aim ~p",[ParseGoal]),
    {_,T,T1} = now(),
    MyResult = 
    case ParseGoal  of
	{ok,halt} ->  
		WebPid ! { <<"No,aim is finished<br/>">>, finish };
	{ok,trace_on} ->  
		WebPid ! { ?TRACE_ON, finish }
	;	    
	{ok,trace_off} ->  
		WebPid ! { ?TRACE_OFF, finish }
      
	;
	{ok, listing} ->  
                
                ResBin = prolog_shell:get_code_memory_html(TreeEts),
                Footer =?MSG_FOOTER,
                WebPid ! {result, <<ResBin/binary," aim is finished<br/>" >> ,finish, self() }
      
	;
	{ok, help} ->  
                ResBin = get_help(),
                Footer = ?MSG_FOOTER,
		WebPid ! {result,<<ResBin/binary," aim is finished<br/>" >>  ,finish, self() }
	;
	{ok, Goal = {':-',_,_ } } ->
		
		WebPid ! {result, <<"No, use online IDE for making rules,aim is finished<br/>">>, finish, self() };
		
	{ok,Goal} when is_tuple(Goal)->
               { TempAim, _ShellContext }=  prolog_shell:make_temp_aim(Goal), 
               ?CONSOLE_LOG("TempAim : ~p~n", [TempAim]),
               prolog_trace:trace_on(TraceStatus, TreeEts, TracePid ),              

               ?CONSOLE_LOG("~p make temp aim ~p ~n",[ {?MODULE,?LINE}, TempAim]),
               StartTime = erlang:now(),
               Res = (catch prolog:aim( finish, ?ROOT, Goal,  dict:new(), 
                                                1, TreeEts, ?ROOT) ),
               process_prove_erws(TempAim, Goal, Res, WebPid, StartTime , TreeEts);
               
        {ok,Goal} ->
        
		WebPid ! {result, <<"No, use online IDE for making rules, aim is finished<br/>">>, finish, self() }
	;
	{error,P = {_, Em, E }} ->
	    ?CONSOLE_LOG(" GOT FROM THER prolog ~p <br/>",[P]),
	    NormalP = result(P),
	    WebPid ! {result, <<"No,aim is finished ~n", NormalP/binary>>, finish, self() };
	Error ->
	    NormalP = result(Error),
	    ?CONSOLE_LOG(" GOT FROM THER prolog ~p ~n",[Error]),
	    WebPid ! {result, <<"No unexpected symbol,aim is finished <br/>">>, finish, self() }
    end,
    ?CONSOLE_LOG(" finish temp ~p ~n",[TreeEts])
.

web_parse_code(P0)->
    {ok, Terms , _L1} = erlog_scan:string( unicode:characters_to_list( P0 ) ),
    erlog_parse:term(Terms).
    
process_prove_erws(TempAim , Goal, Res, WebPid,  StartTime, TreeEts)->
      ProtoType = common:my_delete_element(1, Goal),
      case Res of 

	    {'EXIT',FromPid,Reason}->
		  ?CONSOLE_LOG(" ~p exit aim ~p~n",[?LINE, FromPid]),
		  MainRes = io_lib:format("No<br/> ~p, aim is finished",[Reason]),
		  FinishTime = erlang:now(),
		  ElapsedTime = time_string(FinishTime, StartTime ), 
		  Main =  concat_result( [MainRes,ElapsedTime] ),
		  ?CONSOLE_LOG("~p send back restul to web console ~p",[  {?MODULE,?LINE},
									    {Main, WebPid}]),
		  WebPid ! {result, Main, finish, self() };
	    false ->
		   MainRes = io_lib:format("No<br/>, aim is finished",[]),FinishTime = erlang:now(),
    		   ElapsedTime = time_string(FinishTime, StartTime),
    		   Main =  concat_result( [MainRes,ElapsedTime] ),
		   WebPid ! {result, Main, finish, self() };
	    {true, SomeContext, Prev }->
   		   ?CONSOLE_LOG("~p got from prolog shell aim ~p~n",[?LINE, { ProtoType, SomeContext} ]),
		  FinishTime = erlang:now(),
                  New = prolog_matching:bound_body( 
                                        Goal, 
                                        SomeContext
                                         ),
                  ?CONSOLE_LOG("~p temp  shell cconontext ~p previouse key ~p ~n",[?LINE , New, Prev ]),
                  {true, NewLocalContext} = prolog_matching:var_match(Goal, New, dict:new()),                                                        
                  VarsRes = lists:map(fun shell_var_match_str/1, dict:to_list(NewLocalContext) ),
                  ElapsedTime = time_string(FinishTime, StartTime),                  
		  ResStr = io_lib:format("Yes looking next ?",[] ),
                  Main =  concat_result( [VarsRes, ResStr, ElapsedTime] ),
		  ?CONSOLE_LOG("~p got from prolog shell aim ~p~n",[?LINE, {WebPid, VarsRes, ProtoType, NewLocalContext} ]),	  
		  WebPid ! { result, Main, has_next, self() },
 		  receive 
			 {Line, NewWebPid} ->
			  case Line of
			      finish ->
				    VarRes = io_lib:format("Yes~n",[]),
				    WebPid ! {result, concat_result(VarRes), finish, self() };
                             _->
				    ?CONSOLE_LOG("~p send next to pid ~n",[{?MODULE,?LINE}]),
				    process_prove_erws( TempAim , Goal, 
				    (catch prolog:next_aim(Prev, TreeEts )), 
				    NewWebPid, erlang:now(), TreeEts )		    
			  end
		  end;
             Unexpected->
                  ?CONSOLE_LOG(" ~p exit aim ~p~n",[?LINE, Unexpected]),
                  MainRes = io_lib:format("No<br/> ~p, aim is finished",[Unexpected]),
                  FinishTime = erlang:now(),
                  ElapsedTime = time_string(FinishTime, StartTime ), 
                  Main =  concat_result( [MainRes,ElapsedTime] ),
                  ?CONSOLE_LOG("~p send back restul to web console ~p",[  {?MODULE,?LINE},
                                                                            {Main, WebPid}]),
                  WebPid ! {result, Main, finish, self() }
      end     
.


concat_result(List)->
    list_to_binary(lists:flatten(List)).



% shell_var_match_str({ { Key }, Val} ) when is_float(Val)->
%         shell_var_match_str({ { Key }, float_to_list(Val) } );
% shell_var_match_str({ { Key }, Val} ) when is_integer(Val)->
% 	shell_var_match_str({ { Key }, integer_to_list(Val) } );
% shell_var_match_str({ { Key }, Val} ) when is_binary(Val) -> 
% 			    shell_var_match_str({ { Key }, unicode:characters_to_list(Val) } );
			    
shell_var_match_str({ { Key }, []} )-> 
    io_lib:format("<strong>~p</strong> = nothing ~n", [Key ])
;
shell_var_match_str({ { Key }, Val1} )-> 
    Val  = lists:flatten( erlog_io:write1( Val1 ) ),
    ?CONSOLE_LOG("~p fill shell vars ~p",[{?MODULE,?LINE}, {  Key , Val, Val1} ]),
    case shell_check(Val) of
	true ->
	    
	    io_lib:format("<strong>~p</strong> = ~ts ~n", [Key, Val]);
	false->
	    io_lib:format("<strong>~p</strong> = ~p ~n", [Key, Val])
    end; 
    
shell_var_match_str( V )->
    "".    
    
shell_check([])->
    true;
shell_check([Head|Tail]) when Head<20->
    false
;
shell_check([Head|Tail]) when is_integer(Head)->
    shell_check(Tail)
;

shell_check(_L)->
    false
.
time_string(FinishTime, StartTime)->
  io_lib:format("<br/><span class='time'> elapsed time ~p secs </span><br/>", [ timer:now_diff(FinishTime, StartTime)*0.000001 ] )
.