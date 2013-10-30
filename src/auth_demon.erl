-module(auth_demon).
-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/0, stop/0, status/0, regis_timer_restart/1, regis/2 ,regis/1, kill_process_after/1 ]).
-export([auth/2, deauth/2, 
         get_free_namespace/0,
         return_free_namespace/1,
         try_auth/3,
         low_stop_auth/3,
         free_namespaces/0,
         check_auth/2,
         cache_connections/0,
         post_load/0,
         sync_with_disc/0]).


-record(monitor,{
		  registered_namespaces,
		  registered_ip,
		  auth_info,
		  proc_table	  
                }
                ).
-include("erws_console.hrl").

start_link() ->
	  gen_server:start_link({local, ?MODULE},?MODULE, [],[]).
	  
%%TODO name spaces
init([]) ->
	  ets:new(?AUTH_SESSION, [named_table ,public ,set ]),
          ets:new(?ERWS_LINK, [set, public,named_table ]),
          timer:apply_after(2500, ?MODULE, post_load,[]),
	
          { ok, #monitor{
		     
		      proc_table = ets:new( proc_table_, [named_table ,public ,set ] )
		      } 
	  }
.

post_load()->
    gen_server:cast(?MODULE, post_load)
.


registered_users()->
         {ok, DetsFile} = application:get_env(erws, registered_users_dets  ),
         {ok, RegWorkSpaces} = application:get_env(erws, registered_user_workspaces_dets  ),

         case catch  ets:file2tab(DetsFile) of
            {ok, ?ETS_REG_USERS}->
                ?ETS_REG_USERS;
            _->
                load_backup(registered_users_dets)
         end,
         case catch  ets:file2tab(RegWorkSpaces) of
            {ok, ?ETS_REG_USERS_WORKSPACES}->
                 ?ETS_REG_USERS_WORKSPACES;
            _->
               load_backup(registered_user_workspaces_dets)
               
         end         
.

load_backup(registered_users_dets)->
     {ok, REGISTERED_FILE} = application:get_env(erws, registered_users_dets_backup),
      io:format("~p",[REGISTERED_FILE]),
     {ok, Tab} = ets:file2tab(REGISTERED_FILE),
     Tab;
load_backup(registered_user_workspaces_dets)->
     {ok, REGISTERED_NAMESPACE} = application:get_env(erws, registered_user_workspaces_dets_backup),
     io:format("~p",[REGISTERED_NAMESPACE]),	
     {ok, Tab} =ets:file2tab(REGISTERED_NAMESPACE),
     Tab.

     
     
     
     
generate_avail_namespaces_tables()->
          {ok, Limit}  = application:get_env(erws, limit_of_users),
          ets:new(?ETS_TABLE_USERS, [named_table, private, bag]),
          Free = lists:map(fun(E)-> {free, ?TEMP_PREFIX ++ integer_to_list(E) }  end, lists:seq(1,Limit) ),
          ets:insert(?ETS_TABLE_USERS, Free).

          
get_free_namespace()->         
    gen_server:call(?MODULE, get_free_namespace).
    
free_namespaces()->
    gen_server:call(?MODULE, free_namespaces).
    
return_free_namespace(Namespace)->         
    gen_server:cast(?MODULE, {return_free_namespace,Namespace }).      
        

sync_with_disc()->
      {ok, DetsFile} = application:get_env(erws, registered_users_dets  ),
      {ok, RegWorkSpaces} = application:get_env(erws, registered_user_workspaces_dets  ),
        
      ets:tab2file(?ETS_REG_USERS_WORKSPACES,RegWorkSpaces),
      ets:tab2file(?ETS_REG_USERS, DetsFile )
.
      



code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
    
handle_call(free_namespaces,  _From ,State)->
   Res =  ets:tab2list(?ETS_TABLE_USERS),
   {reply, Res, State};
handle_call( get_free_namespace, _From ,State) ->
    [Head|_List] = ets:lookup(?ETS_TABLE_USERS, free ),
    {free, Name} = Head,  
    ets:delete_object(?ETS_TABLE_USERS, Head),
    {reply, Name, State}
;

handle_call(Info,_From ,State) ->
    ?CONSOLE_LOG("get msg call ~p ~n",
                           [Info]),
    {reply,nothing ,State}
.

try_auth(Ip, OutId, State)->
    api_auth_demon:get_real_namespace_name(OutId).

%     case ets:lookup(?ETS_PUBLIC_SYSTEMS, OutId) of
%         [] -> false;
%         [{_,NameSpace, Config} ]->
%                 try_auth(Ip, NameSpace, State, Config)
%     
%     end.
    

try_auth(Ip, NameSpace, State, Config)->
      Ets = State#monitor.registered_namespaces,
      EtsIp = State#monitor.registered_ip,
      case ets:lookup(Ets, NameSpace ) of
	  [_]-> %already loaded
               cache_auth_ip( check_low_auth(Config, Ip ), Ip,  NameSpace, EtsIp );        
	  []->
	       auth_and_load( check_low_auth(Config, Ip ),  Ip, NameSpace, Config,State)
     end	
.
%%default all ips
check_low_auth({}, _)->
    true;
check_low_auth(Dict, Ip)->
    case dict:find('ips', Dict ) of
        {ok, ListIps}->
            erlang:member(Ip, ListIps);
        %%default all ips
        _ -> true
    end
.    
    


cache_auth_ip(true, Ip, NameSpace, EtsIp)->    
    ets:insert(EtsIp, { {NameSpace, Ip}, true} ),
    true;
cache_auth_ip(false,_Ip,  _NameSpace, _EtsIp)->
    false.   
    
auth_and_load( false, _Ip, _NameSpace, _Config, _State)->
    false;
auth_and_load(true,  Ip, NameSpace, Config,State)->
    start_namespace(NameSpace, Ip, State, Config ),
    true
.

start_namespace( NameSpace, Ip, State, Config)->
  	  EtsNameSpace = State#monitor.registered_namespaces,
  	  EtsIp = State#monitor.registered_ip,
	  ets:insert(EtsIp, { {NameSpace, Ip} , now() }),
          expert_system_start(NameSpace, Config),
	  ets:insert(EtsNameSpace,  {NameSpace , now() }),
          true
.

expert_system_start(NameSpace, Config)->
    case dict:find(source, Config) of
        {ok, { file, FileName  } } ->
             prolog_shell:api_start_anon(NameSpace, FileName);  
        {ok, hbase}->
             prolog_shell:api_start(NameSpace);
        _->
            throw({exception, source_unavalible  })
    end
.


low_stop_auth(State,  Ip, NameSpace)->
    Ets = State#monitor.registered_ip,
    ets:delete(Ets, {NameSpace, Ip})
.

stop() ->
    gen_server:cast(?MODULE, stop).
    
handle_cast(post_load, MyState)->
          generate_avail_namespaces_tables(),
          {ok, CacheConnection} = application:get_env(erws, cache_connection),
          registered_users(),
          timer:apply_interval(CacheConnection, ?MODULE, cache_connections, []),
          {noreply, MyState}
    ;
handle_cast({return_free_namespace, NameSpace }, MyState)->
    ?CONSOLE_LOG("return namespace to the pool msg call ~p ~n",
                           [NameSpace]),
    ets:insert(?ETS_TABLE_USERS, {free, NameSpace}),
    prolog:delete_structs(NameSpace),
    {noreply, MyState};
    
handle_cast(cache_connections, MyState)->
    Res = (catch sync_with_disc()),
%     ?CONSOLE_LOG("syncing with the disk  result is ~p ~n",
%                            [Res]),
    
    {noreply, MyState};
handle_cast( { deauth,  Ip, NameSpace }, MyState) ->
	  %TODO reloading various namespaces
	  low_stop_auth(MyState,Ip, NameSpace ),
         {noreply, MyState};
    
% handle_cast( { regis_timer_restart,  Pid }, MyState) ->
%  	 ?CONSOLE_LOG("~p start monitor ~p ~n",
%                            [ { ?MODULE, ?LINE }, Pid ]),
%          erlang:monitor( process,Pid ),
%          timer:apply_after(?RESTART_CONVERTER,
%                                   ?MODULE,
%                                   kill_process_after, [ Pid ]
%                                  ),
%          ets:insert(MyState#monitor.proc_table, {Pid, timer}),
%    
%          {noreply, MyState};
% handle_cast( { kill_process_after,  Pid }, MyState) ->
%  	?CONSOLE_LOG("~p start monitor ~p ~n",
%                            [ { ?MODULE, ?LINE }, Pid ]),
% 	 %demonitor(Pid),
%          erlang:exit(Pid, by_timer),
%          ets:delete(MyState#monitor.proc_table, Pid),
%          {noreply, MyState};
% handle_cast( { regis,  Pid, Description }, MyState) ->
%  	?CONSOLE_LOG("~p start monitor ~p ~n",
%                            [ { ?MODULE, ?LINE }, Pid ]),
%          erlang:monitor( process, Pid ),
%          ets:insert(MyState#monitor.proc_table, { Pid, Description }),
%          {noreply, MyState};
%          
handle_cast( { regis,  Pid }, MyState) ->
 	?CONSOLE_LOG("~p start monitor ~p ~n",
                           [ { ?MODULE, ?LINE }, Pid ]),
         erlang:monitor( process, Pid ),
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
       
       ?CONSOLE_LOG("~p process  msg ~p  ~n",
                           [ {?MODULE,?LINE}, { Pid,Reason } ]),
       
       ets:delete(State#monitor.proc_table, Pid),
       
       {noreply,  State}
;
handle_info(Info = {'ETS-TRANSFER', SomeTable, FromPid, Prefix}, State)->
        ?CONSOLE_LOG("get finished table ~p ~n",
                           [Info]),
        return_free_namespace(Prefix),                   
        {noreply,  State}
;
handle_info(Info, State) ->
    ?CONSOLE_LOG("get msg  unregistered msg ~p ~n",
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
      List = ets:tab2list( process_information ),
      List.

auth(Ip, NameSpace) when is_binary(NameSpace)->
  auth(Ip, binary_to_list(NameSpace));
auth(Ip, NameSpace )->
  gen_server:call(?MODULE,{auth, Ip, NameSpace}).
  
deauth(Ip, NameSpace) when is_binary(NameSpace)->
  deauth(Ip, binary_to_list(NameSpace));
deauth(Ip, NameSpace )->
  gen_server:cast(?MODULE,{deauth, Ip, NameSpace}).



check_auth(Ip, NameSpace) when is_binary(NameSpace)->
  check_auth(Ip, binary_to_list(NameSpace));
check_auth(Ip, NameSpace)->

    gen_server:call(?MODULE,{check_auth, Ip, NameSpace})
.

cache_connections()->
  gen_server:cast(?MODULE, cache_connections).
  
    
regis_timer_restart(Pid)->
    gen_server:cast(?MODULE,{regis_timer_restart, Pid}).


regis(Pid, Description)->
    gen_server:cast(?MODULE,{regis, Pid, Description}).
    
    
regis(Pid)->
    gen_server:cast(?MODULE,{regis, Pid}).
    

