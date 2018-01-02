%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 10월 2017 오후 4:10
%%%-------------------------------------------------------------------
-module(mysql_query).
-author("Twinny-KJH").

%% API
-export([query/2]).

-include("sql_result_records.hrl").

%% Name,Email,Nickname,Room_idx,User_idx,Read_idx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% query/2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 유저정보 조회
%% return : json encode data
%% 회원가입
query(QueryType,[Id,Pwd,Name,Email,Nickname,Salt]) when QueryType =:= user_register->
  % generate random idx
  Idx = utils:generate_random_int(),
  Sql = "INSERT INTO user (idx,id,pwd,name,email,nickname,salt,regist_datetime) values (?,?, ?, ?, ?, ?,? ,now())",
  Result = utils:query_execute(db,user_register,Sql,[Idx,Id,Pwd,Name,Email,Nickname,Salt]),
  case Result#ok_packet.affected_rows of
    0->
      {error_filed_register,[{<<"message">>,<<"failed register user">>}]};
    _->
      {ok,[{<<"message">>,<<"register user">>}]}
  end
;
%% 설트값 조회
query(QueryType,[User_id]) when QueryType =:= get_salt->
  Sql = "SELECT salt FROM user WHERE id = ? and  remove='false'",
  Result = utils:query_execute(db,user_get_salt,Sql,[User_id]),
  case Result#result_packet.rows of
    []->
      {error_user_not_exist,[{<<"message">>,<<"user not found">>}]};
    _->
      [Result_json] = utils:query_result_to_json_list(Result),
      {ok,Result_json}
  end
;
%% 로그인 체크
%% redis로 활용불가. 최초로 접속하는부분임.
query(QueryType, [User_id,Pwd]) when QueryType =:= user_login->

  Sql = "SELECT * FROM user WHERE id = ? and pwd = ? and remove='false'",
  Result = utils:query_execute(db,user_login,Sql,[User_id,Pwd]),

  case Result#result_packet.rows of
    []->
      {error_failed_login,[{<<"message">>,<<"failed to login">>}]};
    _->
      [Result1] = utils:query_result_to_json_list(Result),
      Sql1 = "UPDATE user SET last_login_datetime=now()  WHERE idx = ?",
      utils:query_execute(db,user_login_update,Sql1,[proplists:get_value(<<"idx">>,Result1)]),

      [Json_result] = utils:query_result_to_json_list(Result),
      % 세션 생성,저장 및 반환
      redis_query_server:insert(Json_result),
      {ok,Session_key} = session_server:insert({proplists:get_value(<<"idx">>,Json_result),User_id}),
      {ok,[{<<"session_key">>,Session_key},{<<"user_nick">>,proplists:get_value(<<"nickname">>,Json_result)}]}
  end;

query(QueryType,[Target_idx]) when QueryType =:= user_info->
  Redis_result = redis_query_server:get_user(Target_idx),
  case Redis_result of
    {ok,undefined}->
      % redis에 등록이 안되있으므로 db조회
      Sql = "SELECT * FROM user WHERE idx = ? and remove='false'",
      Mysql_result = utils:query_execute(db,user_info,Sql,[Target_idx]),
      %redis에 등록
      case Mysql_result#result_packet.rows of
        []->
          {error_user_not_exist,[{<<"message">>,<<"undefined value">>}]};
        _->
          Result = utils:query_result_to_json_list(Mysql_result),
          [Result1] = Result,
          redis_query_server:insert(Result1),
          %db 조회결과 반환
          {ok,[{<<"info">>,Result}]}
      end;
    {ok,_}->
      {ok,RedisVal}=Redis_result,
      {ok,[{<<"info">>,utils:redis2json(RedisVal)}]};
    _->
      {error_redis,[{<<"message">>,<<"error in user_info . case Redis_result : _">>}]}
  end;

%% 유저를 탈퇴시킴
query(QueryType,[User_idx]) when QueryType =:= user_withdrawal ->
  %% 유저를 redis에서 삭제
  redis_query_server:delete(User_idx),
  Sql = "UPDATE user SET remove='true' WHERE idx = ?",
  utils:query_execute(db,user_withdrawal,Sql,[User_idx])
;
%% 닉네임과 이메일 중복 조회
%% redis 로 활용 불가. 검색범위가 너무 넓음.
query(QueryType,[Id,Nickname,Email]) when QueryType =:= check_exist->
  Sql = <<"SELECT * FROM user WHERE (id = ? or email=? or nickname=? ) and remove='false' ">>,
  utils:query_execute(db,check_exist,Sql,[Id,Email,Nickname]);

%% 유저정보 업데이트
query(QueryType,[User_idx,Email,Nickname]) when QueryType =:= update_user->
  redis_query_server:update({User_idx,Email,Nickname}),
  Sql = <<"UPDATE user SET email=?, nickname=? WHERE idx=? and remove='false'">>,
  utils:query_execute(db,update_user,Sql,[Email,Nickname,User_idx]);

query(QueryType,[]) when QueryType =:= board_list->
  Sql = "SELECT * FROM board WHERE remove = 'false'",
  Result = utils:query_execute(db,board_list,Sql,[]),
{ok,[{<<"boards">>,utils:query_result_to_json_list(Result)}]}
;
query(QueryType,[ Post_idx]) when QueryType =:= board_view->
  Sql = "SELECT idx,view_count FROM board WHERE idx = ? and remove='false'",
  Result = utils:query_execute(db,board_view,Sql,[Post_idx]),
  case Result#result_packet.rows of
    []->
      {error_post_not_exist,[{<<"message">>,<<"post is not exist">>}]};
    _->
      %% 업데이트 보드 view_count
      Sql1 = "UPDATE board SET view_count=view_count+1 WHERE idx= ?",
      utils:query_execute(db,board_view_count,Sql1,[Post_idx]),
      mqtt_connect_server:publish_to_mqtt([<<"board">>,utils:add_message(<<"board_view">>,Result),0]),
      {ok,[]}
  end
  ;
query(QueryType,[Board,Title,Contents,User_idx]) when QueryType =:= board_write->
  Board1 = get_board(Board),
  case Board1 of
    error->
      {error_board_not_exist,[{<<"message">>,<<"board not exist">>}]};
    _->
      {ok,Redis_result} = redis_query_server:get_user(User_idx),
      User_data = utils:redis2json(Redis_result),
      User_id = proplists:get_value(<<"id">>,User_data),
      User_nick = proplists:get_value(<<"nickname">>,User_data),
      Sql = "INSERT INTO board (board_name,title,contents,datetime,last_fixed_datetime,user_idx,user_nick,user_id) Values (?,?,?,now(),now(),?,?,?)",
      Result = utils:query_execute(db,board_write,Sql,[Board1,Title,Contents,User_idx,User_nick,User_id]),
      Result_num_row = Result#ok_packet.affected_rows,
      io:format("nick : ~p~n",[User_nick]),
      Sql1 = "SELECT * FROM board order by idx desc limit 1",
      Result1 = utils:query_execute(db,board_writed_select,Sql1,[]),
      mqtt_connect_server:publish_to_mqtt([<<"board">>,utils:add_message(<<"board_write">>,Result1),0]),
      {ok,[{<<"row">>,Result_num_row}]}
  end
;

query(QueryType,[Board,Post_idx,Title,Contents,User_idx]) when QueryType =:= board_fixed->
  Board1 = get_board(Board),
  Result_num_row1 = case Board1 of
    error->
      {error_board_not_exist,[{<<"message">>,<<"board not exist">>}]};
    _->
      Sql = "UPDATE board SET board_name=?, title=?, contents=?,last_fixed_datetime=now() WHERE idx=? and user_idx = ? and remove='false'",
      Result = utils:query_execute(db,board_fixed,Sql,[Board,Title,Contents,Post_idx,User_idx]),
      Result_num_row = Result#ok_packet.affected_rows,
      case Result_num_row of
        0->
          pass;
        _->
          mqtt_connect_server:publish_to_mqtt([<<"board">>,utils:add_message(<<"board_fixed">>,[{<<"idx">>,Post_idx},{<<"board">>,Board},{<<"title">>,Title},{<<"contents">>,Contents}]),0])
      end,
      Result_num_row
  end,
  {ok,[{<<"row">>,Result_num_row1}]}
;
query(QueryType,[Post_idx,User_idx]) when QueryType =:= board_remove->
  Sql = "UPDATE board SET remove='true' WHERE and idx=? and user_idx = ?",
  Result = utils:query_execute(db,board_remove,Sql,[Post_idx,User_idx]),
  Result_num_row = Result#ok_packet.affected_rows,
  case Result_num_row of
    0->
      pass;
    _->
      mqtt_connect_server:publish_to_mqtt([<<"board">>,utils:add_message(<<"board_remove">>,[{<<"idx">>,Post_idx}]),0])
  end,
  {ok,[{<<"row">>,Result_num_row}]}
;
query(QueryType,[User_idx, User_nick,Profile_image_address]) when QueryType =:= fixed_data->
  Sql = "UPDATE user SET nickname = ? , profile_image_address=? WHERE idx = ?",
  Result = utils:query_execute(db,fixed_data,Sql,[User_nick,Profile_image_address,User_idx]),
  Result_num_row = Result#ok_packet.affected_rows,
  case Result_num_row of
    0->
      {error_user_not_exist,[{<<"message">>,<<"error_user_not_exist or not chagned nickname any user">>}]};
    _->
      % redis server에서도 바꿔야함.
      redis_query_server:update_user_data({User_idx,User_nick,Profile_image_address}),
      {ok,[{<<"row">>,Result_num_row}]}
  end
;
query(QueryType,_)->
  {error_query,([{<<"message">>,<<"query type error">>},{<<"type">>,QueryType}])}
.



get_board(Board)->
  case Board of
    <<"tempBoard">>->
      <<"tempBoard">>;
    _->
      error
  end
  .



%% query_execute(db,board_remove,Sql,),

%%fixed_user,[User_idx, User_nick,Profile_image_address]