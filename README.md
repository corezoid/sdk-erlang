# Erlang Corezoid SDK

## Usage

1. Go to the website https://corezoid.com
2. Click on the Users tab
3. Create api user login
4. Take login and secret_key
5. Click on the Process tab
5. Create new process
6. Take conv_id
7. Make erlang code to put new task in that process

```erlang
Login = <<"your_corezoid_api_login">>,
SecretKey = <<"your_secret_key">>,
RefId = null,
ConvId = 1, 
Data = [{<<"key">>, <<"value">>}].


Creds = corezoid:new(Login, SecretKey).
corezoid:create(Creds, ConvId, RefId, Data).
```


