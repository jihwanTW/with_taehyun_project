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

%% API
-export([generate_random_int/0,generate_random_string/0,redis2json/1]).



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