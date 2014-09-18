-module(ejabberd_odbc_wrapper_tests).
-include_lib("eunit/include/eunit.hrl").

-import(ejabberd_odbc_wrapper, [placeArgsInQuery/2, isValidQuery/2, count/3, flattenArgumentList/1]).

run_test_() ->
	[test_blank_query(),
	test_simple_query(),
	test_invalid_marker_count(),
	test_query_with_marker_inside_argument(),
	test_counter(),
	test_flatten_list()].


test_blank_query() ->
	?_assertEqual("", ejabberd_odbc_wrapper:placeArgsInQuery("", [])).

test_invalid_marker_count() ->
	?_assertEqual({false, invalid_marker_count}, ejabberd_odbc_wrapper:isValidQuery("SELECY * FROM my_table WHERE ?='??'", [{"name", "email"}])),
	
	?_assertEqual({false, invalid_marker_count}, ejabberd_odbc_wrapper:isValidQuery("?", ["name", "email"])),

	?_assertEqual({false, empty_query}, ejabberd_odbc_wrapper:isValidQuery("", [])),

	?_assertEqual({true, "WHERE name='Will'"}, ejabberd_odbc_wrapper:isValidQuery("WHERE ?='?'", ["name", "Will"])).

test_simple_query() ->
	?_assertEqual("SELECT * FROM my_table WHERE name='Will'",
		ejabberd_odbc_wrapper:placeArgsInQuery("SELECT * FROM my_table WHERE ?='?'", ["name", "Will"])),

	?_assertEqual("SELECT * FROM my_table WHERE name='Will' AND initial IN ('T','B')",
                ejabberd_odbc_wrapper:placeArgsInQuery("SELECT * FROM my_table WHERE ?='?' AND ? IN (?)", ["name", "Will", "initial", "'T','B'"])).

test_query_with_marker_inside_argument()->
	?_assertEqual("SELECT * FROM my_table WHERE question='How are you?'",
                ejabberd_odbc_wrapper:placeArgsInQuery("SELECT * FROM my_table WHERE ?='?'", ["question", "How are you?"])).

test_counter() ->
	?_assertEqual(0, ejabberd_odbc_wrapper:count("Hello, World", "?", 0)),
	?_assertEqual(0, ejabberd_odbc_wrapper:count("", "?", 0)),
	?_assertEqual(1, ejabberd_odbc_wrapper:count("Hello, World?", "?", 0)),
	?_assertEqual(1, ejabberd_odbc_wrapper:count("?Hello, World", "?", 0)),
	?_assertEqual(2, ejabberd_odbc_wrapper:count("?Hello, World?", "?", 0)),
	?_assertEqual(4, ejabberd_odbc_wrapper:count("?Hello,'?' World??", "?", 0)).
	
test_flatten_list() ->
	?_assertEqual([], ejabberd_odbc_wrapper:flattenArgumentList([])),
	?_assertEqual(["country","brazil"], ejabberd_odbc_wrapper:flattenArgumentList([{<<"country">>,<<"brazil">>}])),	
	?_assertEqual(["country", "brazil", "age", "13"], ejabberd_odbc_wrapper:flattenArgumentList([{<<"country">>,<<"brazil">>}, {<<"age">>, <<"13">>}])).

