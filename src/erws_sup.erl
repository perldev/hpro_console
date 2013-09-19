-module(erws_sup).  
-behaviour(supervisor).  
-export([start_link/0]).  
-export([init/1]).  
-include_lib("eprolog/include/prolog.hrl").  
  
start_link() ->  
        supervisor:start_link({local, ?MODULE}, ?MODULE, []).  
      
init([]) ->  
        LogFunction = fun(Format, Params)->
                         lager:warning(Format, Params)
                       end,
        Restarter = {"monitor",
        {
             converter_monitor, start_link, [ LogFunction ]},
             permanent, infinity, worker , [ converter_monitor]
        },
        AuthDemon = {
        "api_auth_demon",
                {api_auth_demon, start_link, [erws] },
                permanent, infinity, worker , [ api_auth_demon]
        
        },
%         ThriftPool = {"thrift_connection_pool",
%             {thrift_connection_pool, start_link, [ ?DEFAULT_COUNT_THRIFT ] },
%             permanent, infinity, worker , [ thrift_connection_pool ]
%         },
        Auth = {
            "auth_demon",
           { auth_demon, start_link, [  ] },
            permanent, infinity, worker , [ auth_demon ]
        },
        {ok, { {one_for_one, 5, 10}, [Restarter, AuthDemon,  Auth ] } }.  
