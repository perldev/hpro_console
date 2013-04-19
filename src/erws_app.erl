-module(erws_app).  
-behaviour(application).  
-export([start/2, stop/1, start/0]).  
-include("prolog.hrl").
start(_StartType, _StartArgs) ->  
        %% {Host, list({Path, Handler, Opts})}  
        %% Dispatch the requests (whatever the host is) to  
        %% erws_handler, without any additional options.  
        Dispatch = [{'_', [  
            {'_', erws_handler, []}  
        ]}],  
        %% Name, NbAcceptors, Transport, TransOpts, Protocol, ProtoOpts  
        %% Listen in 10100/tcp for http connections.  
        cowboy:start_listener(erws_websocket, 100,  
            cowboy_tcp_transport, [{port, 10000}],  
            cowboy_http_protocol, [{dispatch, Dispatch}]  
        ),  
        
	
        erws_sup:start_link().  
        
start()->
  inets:start(),
  crypto:start(),
  application:start(sasl),
  application:start(crypto),
  application:start(cowboy),
  application:start(compiler),
  application:start(syntax_tools),
  application:start(erws)

.
      
stop(_State) ->  
        ok.  