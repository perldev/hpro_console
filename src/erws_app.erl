-module(erws_app).  
-behaviour(application).  
-export([start/2, stop/1, start/0, web_start/0]).  

-include("erws_console.hrl").

start(_StartType, _StartArgs) ->  
	  
	timer:apply_after(?INIT_APPLY_TIMEOUT,?MODULE,web_start,[]),
	
        erws_sup:start_link().  
        
        
respond(404, Headers, <<>>, Req) ->
        {Path, Req2} = cowboy_req:path(Req),
        Body = <<"404 Not Found: \"", Path/binary, "\" is not the path you are looking for.\n">>,
        Headers2 = lists:keyreplace(<<"content-length">>, 1, Headers,
                {<<"content-length">>, integer_to_list(byte_size(Body))}),
        {ok, Req3} = cowboy_req:reply(404, Headers2, Body, Req2),
        Req3;
respond(Code, Headers, <<>>, Req) when is_integer(Code), Code >= 400 ->
        Body = ["HTTP Error ", integer_to_list(Code), $\n],
        Headers2 = lists:keyreplace(<<"content-length">>, 1, Headers,
                {<<"content-length">>, integer_to_list(iolist_size(Body))}),
        {ok, Req2} = cowboy_req:reply(Code, Headers2, Body, Req),
        Req2;
respond(_Code, _Headers, _Body, Req) ->
        Req.
        

        
web_start()->
        
        Dispatch = cowboy_router:compile([
                                  {'_', [
                                        {"/command/[...]", erws_command, []},
                                        {"/websocket/[...]", erws_handler, []},
                                        {"/prolog/[...]", api_erws_handler, []},%% for using api 
                                        {"/static/[...]", cowboy_static, [
                                        {directory, <<"static">>},
                                        {mimetypes, 
                                        [
                                        {<<".png">>, [<<"image/png">>]},
                                        {<<".jpg">>, [<<"image/jpeg">>]},
                                        {<<".css">>, [<<"text/css">>]},
                                        {<<".js">>, [<<"application/javascript">>]}]
                                        }
                                        ]},
                                        {"/[...]", erws_pages, []}

                                    ]}
                                  ]),
        lists:foreach(  fun({Name, ModuleName})->
                             ok = erlydtl:compile(Name, ModuleName)
                        end, ?TMPLS ),
        {ok, Port } = application:get_env(erws, work_port),       
        {ok, _} = cowboy:start_http(http, 1000, [{port, Port }],
                                                 [
                                                    {env, [{dispatch, Dispatch}]},
                                                    {onresponse, fun respond/4}
                                                 ])
                                                 
.
        
        
start()->
  inets:start(),
  ok = application:start(crypto),
  ok = application:start(ranch),
  ok = application:start(cowboy),
  ok = application:start(asn1),
  ok = application:start(public_key),
  ok = application:start(ssl),
  ok = application:start(compiler),
  ok = application:start(syntax_tools),
  ok = application:start(lager),
  application:start(erws)

.
      
stop(_State) ->  
        ok.  
