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
  emysql:prepare(user_register,<<"INSERT INTO user (idx,id,pwd,name,email,nickname,salt,regist_datetime values(?,?, ?, ?, ?, ?,? ,now())">>),
  Result = emysql:execute(db,user_register,[Idx,Id,Pwd,Name,Email,Nickname,Salt]),
  case Result#ok_packet.affected_rows of
    0->
      {<<"message">>,<<"failed register user">>};
    _->
      {<<"message">>,<<"register user">>}
  end
;
%% 설트값 조회
query(QueryType,[User_id]) when QueryType =:= get_salt->
  emysql:prepare(user_get_salt,<<"SELECT salt FROM user WHERE id = ? and  remove='false'">>),
  Result = emysql:execute(db,user_get_salt,[User_id]),
  case Result#result_packet.rows of
    []->
      {ok,[{<<"result">>,<<"0">>},{<<"message">>,<<"user not found">>}]};
    _->
      [[Result_json]] = emysql_util:as_json(Result),
      {ok,[{<<"result">>,<<"0">>},Result_json]}
  end
;
%% 로그인 체크
%% redis로 활용불가. 최초로 접속하는부분임.
query(QueryType, [User_id,Pwd]) when QueryType =:= user_login->
  emysql:prepare(user_login,<<"SELECT * FROM user WHERE id = ? and pwd = ? and remove='false'">>),
  Result = emysql:execute(db,user_login,[User_id,Pwd]),

  case Result#result_packet.rows of
    []->
      {<<"message">>,<<"failed to login">>};
    _->
      [Json_result] = emysql_util:as_json(Result),
      redis_query_server:login(Json_result),
      % 세션 생성,저장 및 반환
      {ok,Session_key} = session_server:insert({proplists:get_value(<<"idx">>,Json_result),User_id}),
      {<<"session_key">>,Session_key}
  end;

query(QueryType,[Target_idx]) when QueryType =:= user_info->
  Redis_result = redis_query_server:get_user(Target_idx),
  case Redis_result of
    {ok,undefined}->
      % redis에 등록이 안되있으므로 db조회
      emysql:prepare(user_info,<<"SELECT * FROM user WHERE idx = ? and remove='false'">>),
      Mysql_result = emysql:execute(db,user_info,[Target_idx]),
      %redis에 등록
      case Mysql_result#result_packet.rows of
        []->
          [{<<"result">>,<<"undefined value">>}];
        _->
          redis_query_server:insert(Mysql_result),
          %db 조회결과 반환
          [Result|_] = Mysql_result#result_packet.rows,
          emysql_util:as_json(Result)
      end;
    {ok,_}->
      {ok,RedisVal}=Redis_result,
      utils:redis2json(RedisVal);
    _->
      [{<<"result">>,<<"error in user_info . case Redis_result : _">>}]
  end;

%% 유저를 탈퇴시킴
query(QueryType,[User_idx]) when QueryType =:= user_withdrawal ->
  emysql:prepare(user_withdrawal,<<"UPDATE user SET remove='true' WHERE idx = ?">>),
  %% 유저를 redis에서 삭제
  redis_query_server:delete(User_idx),
  emysql:execute(db,user_withdrawal,[User_idx])
;
%% 닉네임과 이메일 중복 조회
%% redis 로 활용 불가. 검색범위가 너무 넓음.
query(QueryType,[Id,Nickname,Email]) when QueryType =:= check_exist->
  emysql:prepare(check_exist,<<"SELECT * FROM user WHERE (id = ? or email=? or nickname=? ) and remove='false' ">>),
  emysql:execute(db,check_exist,[Id,Email,Nickname]);

%% 유저정보 업데이트
query(QueryType,[User_idx,Email,Nickname]) when QueryType =:= update_user->
  redis_query_server:update({User_idx,Email,Nickname}),
  emysql:prepare(update_user,<<"UPDATE user SET email=?, nickname=? WHERE idx=? and remove='false'">>),
  emysql:execute(db,update_user,[Email,Nickname,User_idx]);
query(QueryType,_)->
  ([{<<"result">>,<<"query type error">>},{<<"type">>},{QueryType}])
.
