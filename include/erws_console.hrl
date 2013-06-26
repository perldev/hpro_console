-define('CONSOLE_LOG'(Str, Params), log4erl:info(Str, Params) ).
-define(LISTEN_PORT,10100).

-define(REGISTERED_FILE, "registered.ets" ).
-define(REGISTERED_NAMESPACE, "namespaces.ets" ).
-define(CACHE_CONNECTION, 10000 ).%miliseconds

-define(TEMP_PREFIX, "temp_namespace").
-define(LIMIT_OF_USERS, 1000).
-define(ETS_TABLE_USERS, multi_user_limit).
%%it's means that we will generate max  Rules 1000 tables + 1000 Tree tables 



-define(AUTH_LIST,
		[ 
	       { { {127,0,0,1},  "p24"}, yes  },
	       { { {127,0,0,1},  ""}, yes  },
	       { { {127,0,0,1},  "test"}, yes  },
	       { { {10,1,214,15},  "p24"}, yes  },
	       { { {10,1,214,15},  "p24error"}, yes  }
	       ]
).