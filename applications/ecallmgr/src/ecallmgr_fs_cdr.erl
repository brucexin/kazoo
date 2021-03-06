%%%-------------------------------------------------------------------
%%% @copyright (C) 2012-2013, 2600Hz
%%% @doc
%%%
%%% @end
%%% @contributors
%%%-------------------------------------------------------------------
-module(ecallmgr_fs_cdr).

-behaviour(gen_server).

-export([start_link/1
         ,start_link/2
        ]).
-export([maybe_publish/3,publish/3]).
-export([init/1
         ,handle_call/3
         ,handle_cast/2
         ,handle_info/2
         ,terminate/2
         ,code_change/3
        ]).

-include("ecallmgr.hrl").

-define(SERVER, ?MODULE).

-type fs_to_whistle_map() :: [{ne_binary() | ne_binaries() | fun(), ne_binary()},...].
-define(FS_TO_WHISTLE_MAP, [{<<"FreeSWITCH-Hostname">>, <<"Handling-Server-Name">>}
                            ,{<<"Hangup-Cause">>, <<"Hangup-Cause">>}
                            ,{<<"Unique-ID">>, <<"Call-ID">>}
                            ,{<<"Event-Date-Timestamp">>, <<"Timestamp">>}
                            ,{<<"Call-Direction">>, <<"Call-Direction">>}
                            ,{<<"variable_switch_r_sdp">>, <<"Remote-SDP">>}
                            ,{<<"variable_sip_local_sdp_str">>, <<"Local-SDP">>}
                            ,{<<"variable_sip_to_uri">>, <<"To-Uri">>}
                            ,{<<"variable_sip_from_uri">>, <<"From-Uri">>}
                            ,{[<<"variable_effective_caller_id_number">>, <<"Caller-Caller-ID-Number">>], <<"Caller-ID-Number">>}
                            ,{[<<"variable_effective_caller_id_name">>, <<"Caller-Caller-ID-Name">>], <<"Caller-ID-Name">>}
                            ,{<<"Caller-Callee-ID-Name">>, <<"Callee-ID-Name">>}
                            ,{<<"Caller-Callee-ID-Number">>, <<"Callee-ID-Number">>}
                            ,{<<"Other-Leg-Unique-ID">>, <<"Other-Leg-Call-ID">>}
                            ,{<<"variable_sip_user_agent">>, <<"User-Agent">>}
                            ,{<<"variable_duration">>, <<"Duration-Seconds">>}
                            ,{<<"variable_billsec">>, <<"Billing-Seconds">>}
                            ,{<<"variable_progresssec">>, <<"Ringing-Seconds">>}
                            ,{<<"variable_digits_dialed">>, <<"Digits-Dialed">>}
                            ,{<<"FreeSWITCH-IPv4">>, <<"Handling-Server-IP">>}
                            ,{<<"Channel-Read-Codec-Name">>, <<"Read-Codec-Name">>}
                            ,{<<"Channel-Read-Codec-Rate">>, <<"Read-Codec-Rate">>}
                            ,{<<"Channel-Read-Codec-Bit-Rate">>, <<"Read-Codec-Bit-Rate">>}
                            ,{<<"Channel-Write-Codec-Name">>, <<"Write-Codec-Name">>}
                            ,{<<"Channel-Write-Codec-Rate">>, <<"Write-Codec-Rate">>}
                            ,{<<"Channel-Write-Codec-Bit-Rate">>, <<"Write-Codec-Bit-Rate">>}
                            ,{<<"Caller-Profile-Created-Time">>, <<"Caller-Profile-Created-Time">>}
                            ,{<<"Caller-Channel-Created-Time">>, <<"Caller-Channel-Created-Time">>}
                            ,{<<"Caller-Channel-Answered-Time">>, <<"Caller-Channel-Answered-Time">>}
                            ,{<<"Caller-Channel-Progress-Time">>, <<"Caller-Channel-Progress-Time">>}
                            ,{<<"Caller-Channel-Progress-Media-Time">>, <<"Caller-Channel-Progress-Media-Time">>}
                            ,{<<"Caller-Channel-Hangup-Time">>, <<"Caller-Channel-Hangup-Time">>}
                            ,{<<"Caller-Channel-Transfer-Time">>, <<"Caller-Channel-Transfer-Time">>}
                            ,{<<"Caller-Channel-Resurrect-Time">>, <<"Caller-Channel-Resurrect-Time">>}
                            ,{<<"Caller-Channel-Bridged-Time">>, <<"Caller-Channel-Bridged-Time">>}
                            ,{<<"variable_rtp_audio_in_raw_bytes">>, <<"Audio-In-Raw-Bytes">>}
                            ,{<<"variable_rtp_audio_in_media_bytes">>, <<"Audio-In-Media-Bytes">>}
                            ,{<<"variable_rtp_audio_in_packet_count">>, <<"Audio-In-Packet-Count">>}
                            ,{<<"variable_rtp_audio_in_media_packet_count">>, <<"Audio-In-Media-Packet-Count">>}
                            ,{<<"variable_rtp_audio_in_skip_packet_count">>, <<"Audio-In-Skip-Packet-Count">>}
                            ,{<<"variable_rtp_audio_in_jb_packet_count">>, <<"Audio-In-JB-Packet-Count">>}
                            ,{<<"variable_rtp_audio_in_dtmf_packet_count">>, <<"Audio-In-DTMF-Packet-Count">>}
                            ,{<<"variable_rtp_audio_in_cng_packet_count">>, <<"Audio-In-CNG-Packet-Count">>}
                            ,{<<"variable_rtp_audio_in_flush_packet_count">>, <<"Audio-In-Flush-Packet-Count">>}
                            ,{<<"variable_rtp_audio_in_largest_jb_size">>, <<"Audio-In-Largest-JB-Size">>}
                            ,{<<"variable_rtp_audio_out_raw_bytes">>, <<"Audio-Out-Raw-Bytes">>}
                            ,{<<"variable_rtp_audio_out_media_bytes">>, <<"Audio-Out-Media-Bytes">>}
                            ,{<<"variable_rtp_audio_out_packet_count">>, <<"Audio-Out-Packet-Count">>}
                            ,{<<"variable_rtp_audio_out_media_packet_count">>, <<"Audio-Out-Media-Packet-Count">>}
                            ,{<<"variable_rtp_audio_out_skip_packet_count">>, <<"Audio-Out-Skip-Packet-Count">>}
                            ,{<<"variable_rtp_audio_out_dtmf_packet_count">>, <<"Audio-Out-DTMF-Packet-Count">>}
                            ,{<<"variable_rtp_audio_out_cng_packet_count">>, <<"Audio-Out-CNG-Packet-Count">>}
                            ,{<<"variable_rtp_audio_rtcp_packet_count">>, <<"Audio-RTCP-Packet-Count">>}
                            ,{<<"variable_rtp_audio_rtcp_octet_count">>, <<"Audio_RTCP_Octet_Count">>}
                            ,{<<"ecallmgr">>, <<"Custom-Channel-Vars">>}
                            ,{fun(P) -> ecallmgr_util:get_sip_request(P) end, <<"Request">>}
                            ,{fun(P) -> ecallmgr_util:get_sip_to(P) end, <<"To">>}
                            ,{fun(P) -> ecallmgr_util:get_sip_from(P) end, <<"From">>}
                           ]).
-define(FS_TO_WHISTLE_OUTBOUND_MAP, [{<<"variable_sip_cid_type">>, <<"Caller-ID-Type">>}]).

-record(state, {node :: atom()
                ,options = [] :: wh_proplist()
               }).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link(Node) ->
    start_link(Node, []).

start_link(Node, Options) ->
    gen_server:start_link(?MODULE, [Node, Options], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([Node, Options]) ->
    put('callid', Node),
    lager:info("starting new fs cdr listener for ~s", [Node]),
    gen_server:cast(self(), 'bind_to_events'),
    {'ok', #state{node=Node, options=Options}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    {'reply', {'error', 'not_implemented'}, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast('bind_to_events', #state{node=Node}=State) ->
    case gproc:reg({'p', 'l', {'event', Node, <<"CHANNEL_HANGUP_COMPLETE">>}}) =:= 'true' of
        'true' -> {'noreply', State};
        'false' -> {'stop', 'gproc_badarg', State}
    end;
handle_cast(_Msg, State) ->
    {'noreply', State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info({'event', [UUID | Props]}, #state{node=Node}=State) ->
    spawn(?MODULE, 'maybe_publish', [UUID, Props, Node]),
    {'noreply', State};
handle_info(_Info, State) ->
    lager:debug("unhandled message: ~p", [_Info]),
    {'noreply', State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, #state{node=Node}) ->
    lager:info("cdr listener for ~s terminating: ~p", [Node, _Reason]).

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {'ok', State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
-spec maybe_publish(ne_binary(), wh_proplist(), atom()) -> 'ok'.
maybe_publish(UUID, Props, Node) ->
    put('callid', UUID),	
    ThisNode = wh_util:to_binary(node()),
    %% NOTE: this will significantly reduce AMQP request however if a ecallmgr
    %%   becomes disconnected any calls it previsouly controlled will not produce
    %%   CDRs.  The long-term strategy is to round-robin CDR events from mod_kazoo.
    case ecallmgr_config:get_boolean(<<"restrict_cdr_publisher">>, 'false') of
        'false' -> publish(UUID, Props, Node);
        'true' ->
            case props:get_value(?GET_CCV(<<"Ecallmgr-Node">>), Props, ThisNode) =:= ThisNode of
                'true' -> publish(UUID, Props, Node);
                'false' -> lager:debug("cdr for call controlled by another ecallmgr, not publishing")
            end
    end.

-spec publish(ne_binary(), wh_proplist(), atom()) -> 'ok'.
publish(UUID, Props,_Node) ->
    CDR = create_cdr(Props),
    lager:debug("publishing cdr: ~p", [CDR]),
    wh_amqp_worker:cast(?ECALLMGR_AMQP_POOL
                        ,CDR
                        ,fun(P) -> wapi_call:publish_cdr(UUID, P) end
                       ),
    case props:get_value(<<"Call-Direction">>,CDR) of
        <<"inbound">> ->
            Hangup = props:get_value(<<"Hangup-Cause">>, CDR, <<"unknown">>),
            whistle_stats:increment_counter(get_realm(Props), Hangup);
        _ -> 'ok'
    end.

-spec get_realm(wh_proplist()) -> binary().
get_realm(Props) ->
    [_, Realm] = binary:split(ecallmgr_util:get_sip_from(Props), <<"@">>),
    Realm.  

-spec create_cdr(wh_proplist()) -> wh_proplist().
create_cdr(Props) ->
    DefProp = wh_api:default_headers(<<>>, ?APP_NAME, ?APP_VERSION),
    ApiProp = add_values(?FS_TO_WHISTLE_MAP, DefProp, Props),
    case props:get_value(<<"direction">>, ApiProp) of
        <<"outbound">> -> add_values(?FS_TO_WHISTLE_OUTBOUND_MAP, ApiProp, Props);
        _ -> ApiProp
    end.

-spec add_values(fs_to_whistle_map(), wh_proplist(), wh_proplist()) -> wh_proplist().
add_values(Mappings, BaseProp, ChannelProp) ->
    lists:foldl(fun({Fun, WK}, WApi) when is_function(Fun) ->
                        [{WK, Fun(ChannelProp)} | WApi];
                   ({<<"ecallmgr">>, <<"Custom-Channel-Vars">>=WK}, WApi) ->
                        [{WK, wh_json:from_list(ecallmgr_util:custom_channel_vars(ChannelProp))} | WApi];
                   ({<<"Event-Date-Timestamp">>=FSKey, WK}, WApi) ->
                        case props:get_value(FSKey, ChannelProp) of
                            'undefined' -> WApi;
                            V -> VUnix =  wh_util:unix_seconds_to_gregorian_seconds(wh_util:microseconds_to_seconds(V)),
                                 [{WK, wh_util:to_binary(VUnix)} | WApi]
                        end;
                   ({FSKeys, WK}, WApi) when is_list(FSKeys) ->
                        case get_first_value(FSKeys, ChannelProp) of
                            'undefined' -> WApi;
                            V -> [{WK, V} | WApi]
                        end;
                   ({FSKey, WK}, WApi) ->
                        case props:get_value(FSKey, ChannelProp) of
                            'undefined' -> WApi;
                            V -> [{WK, wh_util:to_binary(V)} | WApi]
                        end
                end, BaseProp, Mappings).

-spec get_first_value(ne_binaries(), wh_proplist()) -> api_binary().
get_first_value([], _) -> 'undefined';
get_first_value([FSKey|T], ChannelProp) ->
    case props:get_value(FSKey, ChannelProp) of
        'undefined' -> get_first_value(T, ChannelProp);
        V -> wh_util:to_binary(V)
    end.
