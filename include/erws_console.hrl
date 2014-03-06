-define('CONSOLE_LOG'(Str, Params), lager:info(Str, Params) ).

-define(INIT_APPLY_TIMEOUT, 1000).


%-define(REGISTERED_FILE, "./expert_system/registered.ets" ).
-define(REGISTERED_NAMESPACE, "./expert_system/namespaces.ets" ).
-define(CACHE_CONNECTION, 10000 ).%miliseconds
-define(DETS_FILE, "./expert_system/regis_users.dets").
-define(ETS_REG_USERS, regis_users).
-define(ETS_REG_USERS_WORKSPACES, path_regis_users).
-define(ETS_REG_USERS_WORKSPACES_DETS, "./expert_system/path_regis_users.dets").

-define(MSG_FOOTER, <<"looking next ?">>).

-define(ERWS_LINK, erws_link_trace).

-define(MAX_UPLOAD, 1600000).
-define(AUTH_SESSION, google_inner_session).  %%connect google and inner session
-define(PATH_TO_SYSTEM, "./expert_system").
-define(TEMP_PREFIX, "temp_namespace").
-define(LIMIT_OF_USERS, 1000).
-define(ETS_TABLE_USERS, multi_user_limit).
-define(GOOGLE_TIMEOUT,50000).
-define(ROUTES, routes() ).

-define( TMPLS,[
            { "tmpl/header.html", header },
            { "tmpl/dev_help.html", tmpl_dev_help },
            { "tmpl/what.html", tmpl_about },
            { "tmpl/index.html", tmpl_index },
            { "tmpl/console.html", tmpl_console },
            { "tmpl/mang.html", tmpl_mang},
            { "tmpl/footer.html", footer},
            { "tmpl/managing_panel.html", tmpl_managing_panel},
            { "tmpl/monitor.html", tmpl_monitor}            
    ]

).


%%it's means that we will generate max  Rules 1000 tables + 1000 Tree tables 


