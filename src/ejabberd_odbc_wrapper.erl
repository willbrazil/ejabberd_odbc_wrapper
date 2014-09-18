-module(ejabberd_odbc_wrapper).
-author('willbrazil.usa@gmail.com').

-include("ejabberd.hrl").
-include("logger.hrl").

-export([select/5,
	 placeArgsInQuery/2,
	 isValidQuery/2,
	 count/3,
	 flattenArgumentList/1]).

%%%-----------------------------
%% Type Declarations
%%-----------------------------
-type is_valid_query_return() :: {false, empty_query} | {false, invalid_marker_count} | {ok, string()}.
-type argument_list() :: [argument_list() | binary()].
-type flat_argument_list() :: [flat_argument_list | string()].
-type select_return() :: any().
-type table_name() :: binary().
-type table_columns() :: [table_columns() | binary()].
-type binary_selection_args() :: [binary_selection_args() | binary()].
-type selection_args() :: [selection_args() | string()].

%%%-----
%%% select: 
%%%-----

-spec select(binary(), table_name(), table_columns(), binary(), binary_selection_args()) -> select_return() | is_valid_query_return().

select(Server, Table, Columns, BinaryQuery, BinaryArgs)->

	Query = binary_to_list(BinaryQuery),
	Args = flattenArgumentList(BinaryArgs),
	ColumnsSql = list_to_binary(string:join(lists:map(fun(El)-> binary_to_list(El) end, Columns), ",")),

	case isValidQuery(Query, Args) of
		{true, ValidQuery} ->
			ejabberd_odbc:sql_query(Server, 
				[<<"SELECT ">>, ColumnsSql, <<" FROM ">>, Table, <<" ">>, ValidQuery]);
		{fale, Error} -> Error
	end.

%%%-----
%%% placeArgsInQuery: Replace each '?' with a respective argument.
%%% e.g. "SELECT * FROM my_table WHERE ?='?'" ---> "SELECT * FROM my_table WHERE name='Will'"
%%%-----

-spec placeArgsInQuery(string(), selection_args()) -> string().

placeArgsInQuery(Query, SelectionArgs) ->

        case SelectionArgs of
		[] -> "";
                [H] -> string:sub_string(Query, 1, string:str(Query, "?")-1) ++ H ++ string:sub_string(Query, string:str(Query, "?")+1, length(Query));
                [H|Tail]->
                        string:sub_string(Query, 1, string:str(Query, "?")-1) ++  H ++ placeArgsInQuery(string:sub_string(Query, string:str(Query, "?")+1, length(Query)), Tail)
        end.


%%%-----
%%% isValidQuery: Given a SQL string with markers (?), check if it's valid. If so, build query. 
%%%-----

-spec isValidQuery(string(), selection_args()) -> is_valid_query_return().
isValidQuery(Query, Args) ->

	case [{Query, count(Query, "?", 0)},{Args, length(Args)}] of
		
		[{_, NumMarkers},{_, NumArgs}] 
			when not (NumMarkers == NumArgs) -> {false, invalid_marker_count};
                [{"",_}, _] -> {false, empty_query};
                _->
			{true, placeArgsInQuery(Query, Args)}
	end.
		

%%%-----
%%% count: Count the number of occurences of 'Char' in the string 'Str'
%%%-----

-spec count(string(), string(), 0) -> non_neg_integer().

count(Str, Char, Count)->
        case {length(Str), string:str(Str, Char)} of
                {0,_} -> Count;
                {_, 0} -> Count;
                {Length,Pos} when Length > 0 ->
                        count(string:sub_string(Str, Pos+1, length(Str)), Char, Count) + 1
        end.

%%%-----
%%% flattenArgumentList: 
%%%-----
-spec flattenArgumentList(argument_list()) ->  flat_argument_list().

flattenArgumentList(ArgList) ->

	case length(ArgList) of
                0 -> [];
                1 ->    
                        [List] = lists:map(fun({Key, Val})-> [binary_to_list(Key), binary_to_list(Val)] end, ArgList),      
                        List;
                _ ->    
                        lists:concat(lists:map(fun({Key, Val})-> [binary_to_list(Key), binary_to_list(Val)] end, ArgList))
        end.
	



