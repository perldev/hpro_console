-module(erws_sup).  
-behaviour(supervisor).  
-export([start_link/0]).  
-export([init/1]).  
  
start_link() ->  

        supervisor:start_link({local, ?MODULE}, ?MODULE, []).  
      

init([]) ->  
	Restarter = {
           "restarter",
           { converter_monitor, start_link, [  ] },
           permanent, infinity, worker , [ converter_monitor ]
        },
        Auth = {
            "auth_demon",
           { auth_demon, start_link, [  ] },
            permanent, infinity, worker , [ auth_demon ]
        },
        {ok, { {one_for_one, 5, 10}, [ Restarter, Auth ] } }.  
