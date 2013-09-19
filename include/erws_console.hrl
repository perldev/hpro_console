-define('CONSOLE_LOG'(Str, Params), lager:info(Str, Params) ).
-define(LISTEN_PORT,8080).

-define(REGISTERED_FILE, "../consoledb/registered.ets" ).
-define(REGISTERED_NAMESPACE, "../consoledb/namespaces.ets" ).
-define(CACHE_CONNECTION, 10000 ).%miliseconds
-define(DETS_FILE, "../consoledb/regis_users.dets").
-define(ETS_REG_USERS, regis_users).
-define(ETS_REG_USERS_WORKSPACES, path_regis_users).

-define(ETS_REG_USERS_WORKSPACES_DETS, "../consoledb/path_regis_users.dets").


-define(MSG_FOOTER, <<"looking next ?">>).


-define(AUTH_SESSION, google_inner_session).  %%connect google and inner session
-define(PATH_TO_SYSTEM, "../consoledb/expert_system").
-define(TEMP_PREFIX, "temp_namespace").
-define(LIMIT_OF_USERS, 1000).
-define(ETS_TABLE_USERS, multi_user_limit).

-define( TMPLS,[
            { "tmpl/header.html", header },
            { "tmpl/dev_help.html", tmpl_dev_help },
            { "tmpl/what.html", tmpl_about },
            { "tmpl/index.html", tmpl_index },
            { "tmpl/console.html", tmpl_console },
            { "tmpl/mang.html", tmpl_mang},
            { "tmpl/footer.html", footer},
            { "tmpl/managing_panel.html", tmpl_managing_panel}
    ]

).


%%it's means that we will generate max  Rules 1000 tables + 1000 Tree tables 


