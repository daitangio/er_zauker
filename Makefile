REBAR=`which rebar || ./rebar`
all: deps compile
deps:
	@$(REBAR) get-deps
compile:
	@$(REBAR) compile
eunit:
	@$(REBAR) skip_deps=true eunit
clean:
	@$(REBAR) clean

cli:
	erl  -name Cli -setCookie ErZaukerCli  -pa lib/eredis/ebin/ -pa ebin/ -eval 'er_zauker_util:load_file("/k/code/erlang/er_zauker/README.txt").'
check:
	@$(REBAR) skip_deps=true build-plt dialyze 
