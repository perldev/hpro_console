-module(erws_pages).

-include("erws_console.hrl").


% Behaviour cowboy_http_handler
-export([init/3, handle/2, terminate/3]).

% Behaviour cowboy_http_websocket_handler



% Called to know how to dispatch a new connection.
init({tcp, http}, Req, _Opts) ->
    io:format("Request: ~p ~n", [ Req ]),
    { Path, Req3} = cowboy_req:path_info(Req),
    { ok, Req3, undefined }
.
    
terminate(_Req, _State, _Reason) ->
    ok.
 

    
% Should never get here.
handle(Req, State) ->

     { Path, Req1} = cowboy_req:path_info(Req),
     ?CONSOLE_LOG(" request to: ~p~n", [Path]),
%       NewReq = cowboy_req:reply(200, [{<<"Content-Type">>, <<"text/html">>}],
%                                 "helo", Req1),
%      {Username, Password, Req2} = credentials(Req1),
      { ok, NewReq } = echo(Path, Req1, State),
      { ok, NewReq, State}
.

echo(Path1 = [<<"dev_help.html">>], Req, _State) ->
           Result = tmpl_dev_help:render([]),          
          ?CONSOLE_LOG("~p try to find file ~p",[?LINE,{Path1 }]),
          {ok, List} = Result,
          ListsFlatten = lists:flatten(List),
          cowboy_req:reply(200, [{<<"Content-Type">>, <<"text/html">>}],
                                ListsFlatten, Req);
                                
echo(Path1 = [<<"console.html">>], Req, _State) ->
           Result = tmpl_console:render([]),          
          ?CONSOLE_LOG("~p try to find file ~p",[?LINE,{Path1}]),
          {ok, List} = Result,
          ListsFlatten  = lists:flatten(List),
          cowboy_req:reply(200, [{<<"Content-Type">>, <<"text/html">>}],
                                ListsFlatten, Req);                                
echo(Path1 = [<<"mang.html">>], Req, _State) ->
          {ok, List} = tmpl_mang:render([]),          
          ?CONSOLE_LOG("~p try to find file ~p",[?LINE,Path1]),
          ListsFlatten = lists:flatten(List),
          cowboy_req:reply(200, [{<<"Content-Type">>, <<"text/html">>}],
                                         ListsFlatten, Req);                                      
echo(Path1 = [<<"what.html">>], Req, _State) ->
          {ok, List} = tmpl_about:render([]),          
          ?CONSOLE_LOG("~p try to find file ~p",[?LINE,Path1]),
          ListsFlatten = lists:flatten(List),
          cowboy_req:reply(200, [{<<"Content-Type">>, <<"text/html">>}],
                                         ListsFlatten, Req);                                         
echo(Path1 = [<<"index.html">>], Req, _State) ->
          ?CONSOLE_LOG("~p try to find file ~p",[?LINE,Path1]),
          {ok, List} = tmpl_index:render([]),          
          ListsFlatten = lists:flatten(List),
          cowboy_req:reply(200, [{<<"Content-Type">>, <<"text/html">>}],
                                         ListsFlatten, Req);
echo([], Req, _State) ->
          ?CONSOLE_LOG("~p empty path",[?LINE]),
          {ok, List}= tmpl_index:render([]),          

          ListsFlatten  = lists:flatten(List),
          cowboy_req:reply(200, [{<<"Content-Type">>, <<"text/html">>}],
                                         ListsFlatten, Req);
echo([<<"favicon.ico">>], Req, _State) ->
          ?CONSOLE_LOG("~p favicon ",[?LINE]),
          ListsFlatten = "",
          cowboy_req:reply(200, [{<<"Content-Type">>, <<"text/html">>}],
                                         ListsFlatten, Req).
           
           
           

