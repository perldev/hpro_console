-module(erws_sup).  
-behaviour(supervisor).  
-export([start_link/0]).  
-export([init/1]).  
-include_lib("eprolog/include/prolog.hrl").  
  
start_link() ->  
        supervisor:start_link({local, ?MODULE}, ?MODULE, []).  
      
init([]) -> 

        AuthDemon = {
                "api_auth_demon",
                {api_auth_demon, start_link, [erws] },
                permanent, infinity, worker , [ api_auth_demon]
        
        },
        Auth = {
            "auth_demon",
           { auth_demon, start_link, [  ] },
            permanent, infinity, worker , [ auth_demon ]
        },
        {ok, { {one_for_one, 5, 10}, [ AuthDemon,  Auth ] } }.  
