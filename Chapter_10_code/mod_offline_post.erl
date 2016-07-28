-module(mod_offline_post).
-author('uday').

-behaviour(gen_mod).
-define(PROCNAME, ?MODULE).

-export([start/2, init/2, stop/1, send_notice/3]).
-include("ejabberd.hrl").
-include("jlib.hrl").
-include("logger.hrl").

start(Host, Opts) ->
    ?INFO_MSG("Starting mod_offline_post", [] ),
    register(?PROCNAME,spawn(?MODULE, init, [Host, Opts])),  
    ok.

init(Host, _Opts) ->
    inets:start(),
    ssl:start(),
    ejabberd_hooks:add(offline_message_hook, Host, ?MODULE, send_notice, 10),
    ok.

stop(Host) ->
    ?INFO_MSG("Stopping mod_offline_post", [] ),
    ejabberd_hooks:delete(offline_message_hook, Host, ?MODULE, send_notice, 10),
    ok.

send_notice(From, To, Packet) ->
	Type = xml:get_tag_attr_s(<<"type">>, Packet),
    Body = xml:get_path_s(Packet, [{elem, <<"body">>}, cdata]),
	To_s = xml:get_tag_attr_s(<<"to">>, Packet),
    Count = mod_offline:count_offline_messages(To#jid.luser, To#jid.lserver),
    Thread = xml:get_path_s(Packet, [{elem, <<"thread">>}, cdata]),
    PostUrl = gen_mod:get_module_opt(To#jid.lserver, ?MODULE, post_url,
        fun(S) -> iolist_to_binary(S) end, list_to_binary("")
    ),
    ?INFO_MSG("Notification for message ~p with ID ~p", [Body, MsgID]),
	if (Type == <<"chat">>)  and (Body /= <<"">>) ->  
	  Sep = "&",
	  Post = [
        "to=", To_s, Sep,
        "thread=", Thread, Sep,        
	    "count=", list_to_binary(integer_to_list(Count)), Sep,
	    "body=", url_encode(binary_to_list(Body)), Sep,
        "from=", From#jid.luser, "@", From#jid.lserver, Sep,
	  ],
	  httpc:request(post, {binary_to_list(PostUrl), [], 
            "application/x-www-form-urlencoded", 
            list_to_binary(Post)
        }, [], [{sync, false}]
      ),
	  ok;
	true ->
	  ok
	end.