ejabberd_odbc_wrapper
=====================

Before you read:
I'm very new to Eralng/ejabberd. I'm 100% open to feedback! I'm posting this here because I really want to learn from you guys! I hope you find this module helpful. This module is also a WIP. I wrote it yesterday and I know there's so much to be done still!


The flexibility that ejabberd_odbc:sql_query/2 gives you is great. Nonetheless, with great power comes great responsability.

ejabberd_odbc:sql_query/2 looks like this:

ejabberd_odbc:sql_query( 
      LServer,
      io_lib:format("select username from users " ++
                    "where username like '~s%' " ++
                    "order by username " ++
                    "limit ~w offset ~w ", [Prefix, Limit, Offset])).
                    
As you can see, it's very powerful since you can easily build your custom SQL queries. Taking a closer look, we can see that table and column names are simply hardcoded into the string. What happens when you have to change the name of a column on the database? Ooops.. We have to replace the old name with the new one all over the place. That's why we use contants, right?

Let's see...

ejabberd_odbc:sql_query(Server,
                        [
                          <<"INSERT INTO ">>,?TABLE,<<" (
                          ">>,?TABLE_COLUMN_USERNAME,<<",
                          ">>,?TABLE_COLUMN_FIRST_NAME,<<",
                          ">>,?TABLE_COLUMN_LAST_NAME,<<"
                          ) VALUES (
                          '">>,Username,<<"',
                          '">>,First,<<"',
                           '">>,Last,<<"'
                          )">>
                        ]),
                      
                      
Ouch... it hurt my eyes just to look at it. Things seem to be all over the place. 


Constants are great. They do solve the "renaming columns" problem but they definitely make your code a bit less readable.

I tried making things a little simples with ejabberd_odbc_wrapper.

%%%------
%%% select(binary(), table_name(), table_columns(), sql_query(), binary_selection_args())
%%%------

ejabberd_odbc_wrapper:select(Server,

                              ?TABLE, 
                              
                              [?TABLE_COLUMN_JID],

                              <<"WHERE ?='?'">>,
                              
                              [{?ROSTERUSERS_TABLE_COLUMN_USERNAME, Username}]
                              
                              ),
                              



