%%%-------------------------------------------------------------------
%%% @copyright (C) 2012-2013, 2600Hz
%%% @doc
%%%
%%% @end
%%% @contributors
%%%   James Aimonetti
%%%-------------------------------------------------------------------
-module(wapi_acdc_stats).

%% Convert JObj or Prop to iolist json
-export([call_waiting/1, call_waiting_v/1
         ,call_missed/1, call_missed_v/1
         ,call_abandoned/1, call_abandoned_v/1
         ,call_handled/1, call_handled_v/1
         ,call_processed/1, call_processed_v/1

         ,current_calls_req/1, current_calls_req_v/1
         ,current_calls_resp/1, current_calls_resp_v/1
        ]).

-export([bind_q/2
         ,unbind_q/2
        ]).

-export([publish_call_waiting/1, publish_call_waiting/2
         ,publish_call_missed/1, publish_call_missed/2
         ,publish_call_abandoned/1, publish_call_abandoned/2
         ,publish_call_handled/1, publish_call_handled/2
         ,publish_call_processed/1, publish_call_processed/2

         ,publish_current_calls_req/1, publish_current_calls_req/2
         ,publish_current_calls_resp/2, publish_current_calls_resp/3
        ]).

-include("acdc.hrl").

-define(REQ_HEADERS, [<<"Call-ID">>, <<"Account-ID">>, <<"Queue-ID">>]).
-define(REQ_VALUES(Name), [{<<"Event-Category">>, <<"acdc_stat">>}
                           ,{<<"Event-Name">>, Name}
                          ]).

-define(WAITING_HEADERS, [<<"Caller-ID-Name">>, <<"Caller-ID-Number">>
                          ,<<"Entered-Timestamp">>
                         ]).
-define(WAITING_VALUES, ?REQ_VALUES(<<"waiting">>)).
-define(WAITING_TYPES, []).

-define(MISS_HEADERS, [<<"Agent-ID">>, <<"Miss-Reason">>, <<"Miss-Timestamp">>]).
-define(MISS_VALUES, ?REQ_VALUES(<<"missed">>)).
-define(MISS_TYPES, []).

-define(ABANDON_HEADERS, [<<"Abandon-Reason">>, <<"Abandon-Timestamp">>]).
-define(ABANDON_VALUES, ?REQ_VALUES(<<"abandoned">>)).
-define(ABANDON_TYPES, []).

-define(HANDLED_HEADERS, [<<"Agent-ID">>, <<"Handled-Timestamp">>]).
-define(HANDLED_VALUES, ?REQ_VALUES(<<"handled">>)).
-define(HANDLED_TYPES, []).

-define(PROCESS_HEADERS, [<<"Agent-ID">>, <<"Processed-Timestamp">>]).
-define(PROCESS_VALUES, ?REQ_VALUES(<<"processed">>)).
-define(PROCESS_TYPES, []).

-spec call_waiting(api_terms()) ->
                          {'ok', iolist()} |
                          {'error', string()}.
call_waiting(Props) when is_list(Props) ->
    case call_waiting_v(Props) of
        'true' -> wh_api:build_message(Props, ?REQ_HEADERS, ?WAITING_HEADERS);
        'false' -> {'error', "Proplist failed validation for call_waiting"}
    end;
call_waiting(JObj) ->
    call_waiting(wh_json:to_proplist(JObj)).

-spec call_waiting_v(api_terms()) -> boolean().
call_waiting_v(Prop) when is_list(Prop) ->
    wh_api:validate(Prop, ?REQ_HEADERS, ?WAITING_VALUES, ?WAITING_TYPES);
call_waiting_v(JObj) ->
    call_waiting_v(wh_json:to_proplist(JObj)).

-spec call_missed(api_terms()) ->
                         {'ok', iolist()} |
                         {'error', string()}.
call_missed(Props) when is_list(Props) ->
    case call_missed_v(Props) of
        'true' -> wh_api:build_message(Props, ?REQ_HEADERS, ?MISS_HEADERS);
        'false' -> {'error', "Proplist failed validation for call_missed"}
    end;
call_missed(JObj) ->
    call_missed(wh_json:to_proplist(JObj)).

-spec call_missed_v(api_terms()) -> boolean().
call_missed_v(Prop) when is_list(Prop) ->
    wh_api:validate(Prop, ?REQ_HEADERS, ?MISS_VALUES, ?MISS_TYPES);
call_missed_v(JObj) ->
    call_missed_v(wh_json:to_proplist(JObj)).

-spec call_abandoned(api_terms()) ->
                            {'ok', iolist()} |
                            {'error', string()}.
call_abandoned(Props) when is_list(Props) ->
    case call_abandoned_v(Props) of
        'true' -> wh_api:build_message(Props, ?REQ_HEADERS, ?ABANDON_HEADERS);
        'false' -> {'error', "Proplist failed validation for call_abandoned"}
    end;
call_abandoned(JObj) ->
    call_abandoned(wh_json:to_proplist(JObj)).

-spec call_abandoned_v(api_terms()) -> boolean().
call_abandoned_v(Prop) when is_list(Prop) ->
    wh_api:validate(Prop, ?REQ_HEADERS, ?ABANDON_VALUES, ?ABANDON_TYPES);
call_abandoned_v(JObj) ->
    call_abandoned_v(wh_json:to_proplist(JObj)).

-spec call_handled(api_terms()) ->
                          {'ok', iolist()} |
                          {'error', string()}.
call_handled(Props) when is_list(Props) ->
    case call_handled_v(Props) of
        'true' -> wh_api:build_message(Props, ?REQ_HEADERS, ?HANDLED_HEADERS);
        'false' -> {'error', "Proplist failed validation for call_handled"}
    end;
call_handled(JObj) ->
    call_handled(wh_json:to_proplist(JObj)).

-spec call_handled_v(api_terms()) -> boolean().
call_handled_v(Prop) when is_list(Prop) ->
    wh_api:validate(Prop, ?REQ_HEADERS, ?HANDLED_VALUES, ?HANDLED_TYPES);
call_handled_v(JObj) ->
    call_handled_v(wh_json:to_proplist(JObj)).

-spec call_processed(api_terms()) ->
                            {'ok', iolist()} |
                            {'error', string()}.
call_processed(Props) when is_list(Props) ->
    case call_processed_v(Props) of
        'true' -> wh_api:build_message(Props, ?REQ_HEADERS, ?PROCESS_HEADERS);
        'false' -> {'error', "Proplist failed validation for call_processed"}
    end;
call_processed(JObj) ->
    call_processed(wh_json:to_proplist(JObj)).

-spec call_processed_v(api_terms()) -> boolean().
call_processed_v(Prop) when is_list(Prop) ->
    wh_api:validate(Prop, ?REQ_HEADERS, ?PROCESS_VALUES, ?PROCESS_TYPES);
call_processed_v(JObj) ->
    call_processed_v(wh_json:to_proplist(JObj)).

-define(CURRENT_CALLS_REQ_HEADERS, [<<"Account-ID">>]).
-define(OPTIONAL_CURRENT_CALLS_REQ_HEADERS, [<<"Queue-ID">>]).
-define(CURRENT_CALLS_REQ_VALUES, [{<<"Event-Category">>, <<"acdc_stat">>}
                                   ,{<<"Event-Name">>, <<"current_calls_req">>}
                                  ]).
-define(CURRENT_CALLS_REQ_TYPES, []).

-spec current_calls_req(api_terms()) ->
                               {'ok', iolist()} |
                               {'error', string()}.
current_calls_req(Props) when is_list(Props) ->
    case current_calls_req_v(Props) of
        'true' -> wh_api:build_message(Props, ?CURRENT_CALLS_REQ_HEADERS, ?OPTIONAL_CURRENT_CALLS_REQ_HEADERS);
        'false' -> {'error', "Proplist failed validation for current_calls_req"}
    end;
current_calls_req(JObj) ->
    current_calls_req(wh_json:to_proplist(JObj)).

-spec current_calls_req_v(api_terms()) -> boolean().
current_calls_req_v(Prop) when is_list(Prop) ->
    wh_api:validate(Prop, ?CURRENT_CALLS_REQ_HEADERS, ?CURRENT_CALLS_REQ_VALUES, ?CURRENT_CALLS_REQ_TYPES);
current_calls_req_v(JObj) ->
    current_calls_req_v(wh_json:to_proplist(JObj)).

-define(CURRENT_CALLS_RESP_HEADERS, [<<"Query-Time">>]).
-define(OPTIONAL_CURRENT_CALLS_RESP_HEADERS, [<<"Waiting">>, <<"Handled">>
                                              ,<<"Abandoned">>, <<"Processed">>
                                             ]).
-define(CURRENT_CALLS_RESP_VALUES, [{<<"Event-Category">>, <<"acdc_stat">>}
                                    ,{<<"Event-Name">>, <<"current_calls_resp">>}
                                   ]).
-define(CURRENT_CALLS_RESP_TYPES, []).

-spec current_calls_resp(api_terms()) ->
                                {'ok', iolist()} |
                                {'error', string()}.
current_calls_resp(Props) when is_list(Props) ->
    case current_calls_resp_v(Props) of
        'true' -> wh_api:build_message(Props, ?CURRENT_CALLS_RESP_HEADERS, ?OPTIONAL_CURRENT_CALLS_RESP_HEADERS);
        'false' -> {'error', "Proplist failed validation for current_calls_resp"}
    end;
current_calls_resp(JObj) ->
    current_calls_resp(wh_json:to_proplist(JObj)).

-spec current_calls_resp_v(api_terms()) -> boolean().
current_calls_resp_v(Prop) when is_list(Prop) ->
    wh_api:validate(Prop, ?CURRENT_CALLS_RESP_HEADERS, ?CURRENT_CALLS_RESP_VALUES, ?CURRENT_CALLS_RESP_TYPES);
current_calls_resp_v(JObj) ->
    current_calls_resp_v(wh_json:to_proplist(JObj)).

bind_q(Q, Props) ->
    amqp_util:whapps_exchange(),

    QID = props:get_value('queue_id', Props, <<"*">>),
    AcctId = props:get_value('account_id', Props, <<"*">>),

    bind_q(Q, AcctId, QID, props:get_value('restrict_to', Props)).

bind_q(Q, AcctId, QID, 'undefined') ->
    amqp_util:bind_q_to_whapps(Q, call_stat_routing_key(AcctId, QID)),
    amqp_util:bind_q_to_whapps(Q, query_stat_routing_key(AcctId, QID));
bind_q(Q, AcctId, QID, ['call_stat'|L]) ->
    amqp_util:bind_q_to_whapps(Q, call_stat_routing_key(AcctId, QID)),
    bind_q(Q, AcctId, QID, L);
bind_q(Q, AcctId, QID, ['query_stat'|L]) ->
    amqp_util:bind_q_to_whapps(Q, query_stat_routing_key(AcctId, QID)),
    bind_q(Q, AcctId, QID, L);
bind_q(Q, AcctId, QID, [_|L]) ->
    bind_q(Q, AcctId, QID, L).

unbind_q(Q, Props) ->
    QID = props:get_value('queue_id', Props, <<"*">>),
    AcctId = props:get_value('account_id', Props, <<"*">>),

    unbind_q(Q, AcctId, QID, props:get_value('restrict_to', Props)).

unbind_q(Q, AcctId, QID, 'undefined') ->
    amqp_util:unbind_q_from_whapps(Q, call_stat_routing_key(AcctId, QID)),
    amqp_util:unbind_q_from_whapps(Q, query_stat_routing_key(AcctId, QID));
unbind_q(Q, AcctId, QID, ['call_stat'|L]) ->
    amqp_util:unbind_q_from_whapps(Q, call_stat_routing_key(AcctId, QID)),
    unbind_q(Q, AcctId, QID, L);
unbind_q(Q, AcctId, QID, ['query_stat'|L]) ->
    amqp_util:unbind_q_from_whapps(Q, query_stat_routing_key(AcctId, QID)),
    unbind_q(Q, AcctId, QID, L);
unbind_q(Q, AcctId, QID, [_|L]) ->
    unbind_q(Q, AcctId, QID, L).

publish_call_waiting(JObj) ->
    publish_call_waiting(JObj, ?DEFAULT_CONTENT_TYPE).
publish_call_waiting(API, ContentType) ->
    {'ok', Payload} = wh_api:prepare_api_payload(API, ?WAITING_VALUES, fun call_waiting/1),
    amqp_util:whapps_publish(call_stat_routing_key(API), Payload, ContentType).

publish_call_missed(JObj) ->
    publish_call_missed(JObj, ?DEFAULT_CONTENT_TYPE).
publish_call_missed(API, ContentType) ->
    {'ok', Payload} = wh_api:prepare_api_payload(API, ?MISS_VALUES, fun call_missed/1),
    amqp_util:whapps_publish(call_stat_routing_key(API), Payload, ContentType).

publish_call_abandoned(JObj) ->
    publish_call_abandoned(JObj, ?DEFAULT_CONTENT_TYPE).
publish_call_abandoned(API, ContentType) ->
    {'ok', Payload} = wh_api:prepare_api_payload(API, ?ABANDON_VALUES, fun call_abandoned/1),
    amqp_util:whapps_publish(call_stat_routing_key(API), Payload, ContentType).

publish_call_handled(JObj) ->
    publish_call_handled(JObj, ?DEFAULT_CONTENT_TYPE).
publish_call_handled(API, ContentType) ->
    {'ok', Payload} = wh_api:prepare_api_payload(API, ?HANDLED_VALUES, fun call_handled/1),
    amqp_util:whapps_publish(call_stat_routing_key(API), Payload, ContentType).

publish_call_processed(JObj) ->
    publish_call_processed(JObj, ?DEFAULT_CONTENT_TYPE).
publish_call_processed(API, ContentType) ->
    {'ok', Payload} = wh_api:prepare_api_payload(API, ?PROCESS_VALUES, fun call_processed/1),
    amqp_util:whapps_publish(call_stat_routing_key(API), Payload, ContentType).

publish_current_calls_req(JObj) ->
    publish_current_calls_req(JObj, ?DEFAULT_CONTENT_TYPE).
publish_current_calls_req(API, ContentType) ->
    {'ok', Payload} = wh_api:prepare_api_payload(API, ?CURRENT_CALLS_REQ_VALUES, fun current_calls_req/1),
    amqp_util:whapps_publish(query_stat_routing_key(API), Payload, ContentType).

publish_current_calls_resp(RespQ, JObj) ->
    publish_current_calls_resp(RespQ, JObj, ?DEFAULT_CONTENT_TYPE).
publish_current_calls_resp(RespQ, API, ContentType) ->
    {'ok', Payload} = wh_api:prepare_api_payload(API, ?CURRENT_CALLS_RESP_VALUES, fun current_calls_resp/1),
    amqp_util:targeted_publish(RespQ, Payload, ContentType).

call_stat_routing_key(Prop) when is_list(Prop) ->
    call_stat_routing_key(props:get_value(<<"Account-ID">>, Prop)
                          ,props:get_value(<<"Queue-ID">>, Prop)
                         );
call_stat_routing_key(JObj) ->
    call_stat_routing_key(wh_json:get_value(<<"Account-ID">>, JObj)
                          ,wh_json:get_value(<<"Queue-ID">>, JObj)
                         ).
call_stat_routing_key(AcctId, QID) ->
    <<"acdc_stats.call.", AcctId/binary, ".", QID/binary>>.

query_stat_routing_key(Prop) when is_list(Prop) ->
    query_stat_routing_key(props:get_value(<<"Account-ID">>, Prop)
                           ,props:get_value(<<"Queue-ID">>, Prop)
                          );
query_stat_routing_key(JObj) ->
    query_stat_routing_key(wh_json:get_value(<<"Account-ID">>, JObj)
                           ,wh_json:get_value(<<"Queue-ID">>, JObj)
                          ).

query_stat_routing_key(AcctId, 'undefined') ->
    <<"acdc_stats.query.", AcctId/binary, ".all">>;
query_stat_routing_key(AcctId, QID) ->
    <<"acdc_stats.query.", AcctId/binary, ".", QID/binary>>.