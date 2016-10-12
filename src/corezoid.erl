-module(corezoid).


-export([new/2, new/3]).
-export([create/4]).
-export([modify/4]).
-export([direct/2]).

-record(corezoid, {
	login,
	secret,
	host = <<"https://www.corezoid.com">>
}).






%%%%%%%%%%%%%%%% API 




-spec new(binary(), binary()) -> {ok, #corezoid{}}.
new(Login, Secret)->
    {ok, #corezoid{
		login  = Login,
		secret = Secret
	}}.

-spec new(binary(), binary(), binary()) -> {ok, #corezoid{}}.
new(Login, Secret, Host)->
    {ok, #corezoid{
		login  = Login,
		secret = Secret,
		host   = Host
	}}.





-spec create(#corezoid{}, integer(), binary(), list() | map()) -> {ok, list()} | {error, binary(), any()}.
create(CorRec, ConvId, RefId, Data)->
    send(CorRec, ConvId, RefId, Data, <<"create">>).








-spec modify(#corezoid{}, integer(), binary(), list() | map()) -> {ok, list()} | {error, binary(), any()}.
modify(CorRec, ConvId, RefId, Data)->
    send(CorRec, ConvId, RefId, Data, <<"modify">>).







-spec direct(binary(), list() | map()) -> {ok, list()} | {error, binary(), any()}.
direct(DirectUrl, Data)->
	request(DirectUrl, jsx:encode(Data)).







%%%%%%%%%%%%%%%%%%%%%%%%%%% LOCAL 




-spec send(#corezoid{}, integer(), binary(), list() | map(), binary()) -> {ok, list()} | {error, binary(), any()}.
send(CorRec, ConvId, RefId, Data, Type)->  

    Ops = [
    	{<<"ops">>, [
    		{<<"ref">>, RefId},
	        {<<"type">>, Type}, % create | modify
	        {<<"obj">>, <<"task">>},
	        {<<"conv_id">>, ConvId},
	        {<<"data">>, Data}
    	]}        
    ],
    Json = jsx:encode(Ops),
    Url  = to_url(CorRec, Json),
    request(Url, Json).







request(Url, Json)->
    Headers = [
    	{"Content-Type", "text/xml; charset=\"utf-8\""}, 
    	{"Accept", "application/json"}
    ],
    Res = httpc:request(post, {Url, Headers, "application/octet-stream", Json}, [], [{body_format, binary}]),    

    case Res of

        {ok, {_, _, Body}} ->

                RespJson = (catch jsx:decode(Body)),

			    case is_list(RespJson) of

			        true ->

			                Rproc = proplists:get_value(<<"request_proc">>, RespJson),

			                case Rproc of

			                    <<"ok">> ->

			                    	Ops = proplists:get_value(<<"ops">>, RespJson),
			                        
			                        [RespOp | _] = Ops,			                     	
			                        OpsFix = 
			                        case is_list(RespOp) of
			                        	true -> Ops;
			                        	_    -> [Ops]
			                        end,

			                        [Op | _] = OpsFix,
			                        Proc = proplists:get_value(<<"proc">>, Op),
			                        case Proc of

			                            <<"ok">> ->  
			                                
			                                {ok, OpsFix};

			                            _        ->

			                                {error, Proc, RespJson}

			                        end;

			                    _        ->

			                        {error, Rproc, RespJson}
			                end;

			        _    ->

			                {error, <<"invalid_json">>, []}

			    end;

        Other   ->
              
            {error, <<"http_error">>, Other}

    end.






   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  LOCAL






to_url(CorRec, Json)->	
	Host   = CorRec#corezoid.host,
	Login  = CorRec#corezoid.login,
	Secret = CorRec#corezoid.secret,
	Time   = integer_to_binary(erlang:system_time(seconds)),
	SignBin= <<Time/binary, Secret/binary, Json/binary, Secret/binary>>,
   	Sign   = bin_to_hexstr( crypto:hash(sha, SignBin)),
    binary_to_list(<<
    	Host/binary, "/api/1/json/", 
    	Login/binary, "/", 
    	Time/binary, "/", 
    	Sign/binary>>
    ).







%%%%%%%%%%%%%%%%%%%%%%%%%% INTERNAL





hex(N) when N < 10 ->
    $0+N;
hex(N) when N >= 10, N < 16 ->
    $a+(N-10).
    
to_hex(N) when N < 256 ->
    [hex(N div 16), hex(N rem 16)].
 
list_to_hexstr([]) -> 
    [];
list_to_hexstr([H|T]) ->
    to_hex(H) ++ list_to_hexstr(T).

bin_to_hexstr(Bin)when is_binary(Bin) ->
     list_to_binary( list_to_hexstr( binary_to_list(Bin)) );
bin_to_hexstr(S) ->
     list_to_binary( list_to_hexstr( S ) ).