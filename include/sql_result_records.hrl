%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 11월 2017 오후 9:14
%%%-------------------------------------------------------------------
-author("Twinny-KJH").

%% API
-export([]).


-record(ok_packet, {seq_num, affected_rows, insert_id, status, warning_count, msg}).

-record(result_packet, {seq_num, field_list, rows, extra}).

-record(error_packet, {seq_num, code, msg}).