-module(ua).

-behaviour(gen_server).


% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([start_link/0, info/1, os_with_version/5]).
-record(state, {config, servername}).
-include("prolog.hrl").
-define(DATA_FILE, "user_agents.json").



info(UA)->
	case ets:lookup(ua_cache, UA) of
		[{_, Cache}] -> 
						Cache;
		_   ->
				Browser = browser(UA),
				Browscap= os(UA, Browser),
				ets:insert(ua_cache, {UA, Browscap}),
				Browscap
	end.


browser(UA)->
	case parse(UA, ua_browser) of
		{{_Re, Family, V1, V2, V3}, Params} ->
				#browscap{
					browser  = value(Family, Params, 2), 
					version  = value(V1, Params, 3), 
					majorver = value(V2, Params, 4),  
					minorver = value(V3, Params, 5)
				};
		_  ->
				undefined
	end.

os(UA, undefined)->
	os(UA, #browscap{});
os(UA, Browscap)->
	case parse(UA, ua_os) of
		{{_Re, Os, _V1, _V2, _V3, _V4}, Params} ->
				Name     = value(Os, Params, 1),
				%Version1 = value(V1, Params, 2),
				%Version2 = value(V2, Params, 3),
				%Version3 = value(V3, Params, 4),
				%Version4 = value(V4, Params, 5),
				Browscap#browscap{
					platform = Name
				};
		_  ->
				Browscap
	end.


parse(UA, Table)->
	parse(UA, Table, ets:first(Table)).

parse(_UA, _Table, '$end_of_table')->
	undefined;

parse(UA, Table, Key)->
	case re:run(UA, Key, [global, {capture, all, binary}]) of
		{match,[Data]} -> 
					[Params] = ets:lookup(Table, Key),
					{Params, Data};
		_  ->
				parse(UA, Table, ets:next(Table, Key))
	end.



value(null, Params, Number)->
	case length(Params) >= Number of
		true -> lists:nth(Number, Params);
		_    -> null
	end;

value(Param, Params, 2)->
	case length(Params) >= 2 of
		true -> 
				Replace = lists:nth(2, Params),
				case is_binary(Replace) of
					true -> binary:replace(Param, <<"$1">>, Replace);
					_    -> Param
				end;
		_    -> 
				Param
	end;
value(Param, _, _)->
	Param.


os_with_version(null, null, null, null, null)->
	null;
os_with_version(Name, null, null, null, null)->
	Name;
os_with_version(Name, Version1, null, null, null)->
	<<Name/binary, " ", Version1/binary>>;
os_with_version(Name, Version1, Version2, null, null)->
	<<Name/binary, " ", Version1/binary, ".", Version2/binary>>;
os_with_version(Name, Version1, Version2, Version3, null)->
	<<Name/binary, " ", Version1/binary, ".", Version2/binary, ".", Version3/binary>>;
os_with_version(Name, Version1, Version2, Version3, Version4)->
	<<Name/binary, " ", Version1/binary, ".", Version2/binary, ".", Version3/binary, ".", Version4/binary>>.


start_link()->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init(_)-> 

	ets:new(ua_browser, [set, protected, named_table]),
    ets:new(ua_os, [set, protected, named_table]),
    ets:new(ua_cache, [set, public, named_table]),

	{ok, Content} = file:read_file(?DATA_FILE),
	Parsers       = jsx:decode(Content),

	UaParsers = proplists:get_value(<<"user_agent_parsers">>, Parsers),
	OsParsers = proplists:get_value(<<"os_parsers">>, Parsers),


    lists:foreach(fun(UaParser)-> 
    	Re     = proplists:get_value(<<"regex">>, UaParser),
    	Family = proplists:get_value(<<"family_replacement">>, UaParser, null),
    	V1     = proplists:get_value(<<"v1_replacement">>, UaParser, null),
    	V2     = proplists:get_value(<<"v2_replacement">>, UaParser, null),
    	V3     = proplists:get_value(<<"v3_replacement">>, UaParser, null),
    	ets:insert(ua_browser, {Re, Family, V1, V2, V3})
    end, UaParsers),


    lists:foreach(fun(OsParser)-> 
    	Re = proplists:get_value(<<"regex">>, OsParser),
    	Os = proplists:get_value(<<"os_replacement">>, OsParser, null),
    	V1 = proplists:get_value(<<"v1_replacement">>, OsParser, null),
    	V2 = proplists:get_value(<<"v2_replacement">>, OsParser, null),
    	V3 = proplists:get_value(<<"v3_replacement">>, OsParser, null),
    	V4 = proplists:get_value(<<"v4_replacement">>, OsParser, null),
    	ets:insert(ua_os, {Re, Os, V1, V2, V3, V4})
    end, OsParsers),
          
    {ok, #state{}}.
      


% handle_call generic fallback
handle_call(_Request, _From, State) ->
    {reply, undefined, State}.


% manual shutdown
handle_cast(stop, State) ->
    {stop, normal, State};
            
    
% handle_cast generic fallback (ignore)
handle_cast(_Msg, State) ->
    {noreply, State}.


    
% handle_info generic fallback (ignore)
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
	terminated.
        
code_change(_OldVsn, State, _Extra) ->
	{ok, State}.


