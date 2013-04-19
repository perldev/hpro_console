-module(converter_monitor).
-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/0, stop/0, status/0,stat/4,statistic/0, regis_timer_restart/1, regis/2 ,regis/1, kill_process_after/1 ]).
-export([stop_converter/0, start_converter/0 ]).



-record(monitor,{
		  proc_table
                }
                ).
-include("prolog.hrl").

start_link() ->
	  gen_server:start_link({local, ?MODULE},?MODULE, [],[]).

init([]) ->
	 common:prepare_log("log/e_"),
	 ?LOG_APPLICATION,
	 prolog:create_inner_structs(),
         ?INCLUDE_HBASE,
         ets:new(?ERWS_LINK, [set, public,named_table ]),
      	 converter_monitor:start_converter(),
         { ok, #monitor{proc_table = ets:new( process_information, [named_table ,public ,set ] ) } }
.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.



    
handle_call(Info,_From ,State) ->
    ?WAIT("get msg call ~p ~n",
                           [Info]),
    {reply,nothing ,State}
.
stop() ->
    gen_server:cast(?MODULE, stop).


handle_cast( { regis_timer_restart,  Pid }, MyState) ->
 	 ?WAIT("~p start monitor ~p ~n",
                           [ { ?MODULE, ?LINE }, Pid ]),
         erlang:monitor( process,Pid ),
         timer:apply_after(?RESTART_CONVERTER,
                                  ?MODULE,
                                  kill_process_after, [ Pid ]
                                 ),
         ets:insert(MyState#monitor.proc_table, {Pid, timer}),
   
         {noreply, MyState};
handle_cast( { kill_process_after,  Pid }, MyState) ->
 	?WAIT("~p start monitor ~p ~n",
                           [ { ?MODULE, ?LINE }, Pid ]),
	 %demonitor(Pid),
         erlang:exit(Pid, by_timer),
         ets:delete(MyState#monitor.proc_table, Pid),
         {noreply, MyState};
handle_cast( { regis,  Pid, Description }, MyState) ->
 	?WAIT("~p start monitor ~p ~n",
                           [ { ?MODULE, ?LINE }, Pid ]),
         erlang:monitor( process, Pid ),
         ets:insert(MyState#monitor.proc_table, { Pid, Description }),
         {noreply, MyState};
         
handle_cast( { regis,  Pid }, MyState) ->
 	?WAIT("~p start monitor ~p ~n",
                           [ { ?MODULE, ?LINE }, Pid ]),
         erlang:monitor( process, Pid ),
         ets:insert(MyState#monitor.proc_table, {Pid, watch}),
         {noreply, MyState}.
% ----------------------------------------------------------------------------------------------------------
% Function: handle_info(Info, State) -> {noreply, State} | {noreply, State, Timeout} | {stop, Reason, State}
% Description: Handling all non call/cast messages.
% ----------------------------------------------------------------------------------------------------------
% handle info when child server goes down
% {'DOWN',#Ref<0.0.0.73>,process,<0.56.0>,normal}
kill_process_after(Pid)->
     gen_server:cast(?MODULE, {kill_process_after, Pid}).

    


handle_info({'DOWN',_,_,Pid,Reason}, State)->
       
       ?WAIT("~p process  msg ~p  ~n",
                           [ {?MODULE,?LINE}, { Pid,Reason } ]),
       
       ets:delete(State#monitor.proc_table, Pid),
       
       {noreply,  State}
;
handle_info(Info, State) ->
    ?WAIT("get msg  unregistered msg ~p ~n",
                           [Info]),

    {noreply,  State}.


% ----------------------------------------------------------------------------------------------------------
% Function: terminate(Reason, State) -> void()
% Description: This function is called by a gen_server when it is about to terminate. When it returns,
% the gen_server terminates with Reason. The return value is ignored.
% ----------------------------------------------------------------------------------------------------------
terminate(_Reason, _State) ->
   terminated.

status()->
      List = ets:tab2list( process_information ),List.

statistic()->
    ListType = ets:foldl(fun( {  { Type, Name }  , {true, TrueCount, false, FalseCount } }, In )->
% 		  jsx:encode( [ {'Type', [  [{'Name', 2}], [{'Name2',1}]    ]  }  ]).
		  NewVal = [ {Type, [   [ { Name, TrueCount } ], [ {Name, FalseCount } ]  ]  }  ],
		  [NewVal | In]
		  end, [], ?STAT),
    ListType
    .
    
    
regis_timer_restart(Pid)->
    gen_server:cast(?MODULE,{regis_timer_restart, Pid}).


regis(Pid, Description)->
    gen_server:cast(?MODULE,{regis, Pid, Description}).
    
    
regis(Pid)->
    gen_server:cast(?MODULE,{regis, Pid}).
    
stop_converter()->
    ets:insert(?APPLICATION,{converter_run, false}).
start_converter()->
    ets:insert(?APPLICATION,{converter_run, true}).   
    
%%prototype do not use     
stat(Type, Name,  _ProtoType, Res)->
    Key  =  { Type, Name },
    case ets:lookup(?STAT, { Type, Name }) of
	[ {Key, {true, TrueCount, false, FalseCount  }} ]->
		case Res of
		    true->
			ets:insert(?STAT, { Key, {true, TrueCount+1, false, FalseCount }  } );
		    false->
			ets:insert(?STAT, { Key, {true, TrueCount, false, FalseCount+1 }   })
		end;
	      
	[  ]->
		case Res of
		    true->
			ets:insert(?STAT, { Key, {true, 1, false, 0 } }  );
		    false->
			ets:insert(?STAT ,{Key, {true, 0, false, 1 } }  )
		end
		
	end


    
.
    