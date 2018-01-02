%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 11월 2017 오후 2:22
%%%-------------------------------------------------------------------
-module(utils).
-author("Twinny-KJH").

-include("sql_result_records.hrl").
%% API
-export([
  generate_random_int/0,
  generate_random_string/0,
  redis2json/1,
  list2json_binary/1,
  query_execute/4,
  query_result_to_json_list/1,
  query_to_json_binary/1,
  covered_name/2,
  add_message/2
]).



generate_random_int()->
  <<A:32,B:32,C:32>> = crypto:rand_bytes(12),
  random:seed(A,B,C),
  random:uniform(2100000000)
.

generate_random_string()->
  base64:encode(crypto:strong_rand_bytes(6))
.


redis2json([])->
  undefined;
redis2json(List)->
  redis2json(List,[])
.


redis2json([],Result)->
  Result;
redis2json([Key,Value|T],Result)->
  Result2 = Result++[{Key,Value}],
  redis2json(T,Result2)
.

list2json_binary(Binary)->
  jsx:encode(Binary)
.

query_execute(Db,Pool,Sql,Param)->
  emysql:prepare(Pool,Sql),
  emysql:execute(Db,Pool,Param)
.

query_result_to_json_list(Query_result)->
  emysql_util:as_json(Query_result)
  .

query_to_json_binary(Query_result)->
  list2json_binary(query_result_to_json_list(Query_result))
  .


covered_name(Covered_name,Query_result)->
  Result1 = length(Query_result#result_packet.rows),
  Result2 = case Result1 of
             1->
               [New_result] = query_result_to_json_list(Query_result),
               New_result;
             _->
               query_result_to_json_list(Query_result)
           end,
  list2json_binary([{Covered_name, Result2}])
  .

add_message(Msg,Query_result = #result_packet{rows = Rows}) ->
  Result1 = length(Rows),
  Result2 = case Result1 of
              1->
                [New_result] = query_result_to_json_list(Query_result),
                New_result;
              _->
                query_result_to_json_list(Query_result)
            end,
  list2json_binary([{<<"message">>,Msg},{<<"board">>, Result2}])
  ;
add_message(Msg,Json_list) ->
  list2json_binary([{<<"message">>,Msg},{<<"board">>, Json_list}])
.