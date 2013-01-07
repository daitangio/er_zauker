REBAR=`which rebar || ./rebar`
all: deps compile
deps:
	@$(REBAR) get-deps
compile:
	@$(REBAR) compile
eunit:
	@$(REBAR) --verbose skip_deps=true eunit
clean:
	@$(REBAR) clean

cli:
	## erl  -name Cli -setCookie ErZaukerCli  -pa lib/eredis/ebin/ -pa ebin/ -eval 'er_zauker_util:load_file("/k/code/erlang/er_zauker/README.txt").'
	erl  -name Cli -setCookie ErZaukerCli  -pa lib/eredis/ebin/ -pa ebin/ -eval 'pman:start(),er_zauker_app:startIndexer(),er_zauker_indexer!{self(),directory,"/k/code/code_zauker/lib"}.'

icbpi-test:
	erl  -name Cli -setCookie ErZaukerCli  -pa lib/eredis/ebin/ -pa ebin/ -eval 'er_zauker_app:startIndexer(),er_zauker_indexer!{self(),directory,"/d/ICBPI/icbpi-dev/mps/"},er_zauker_indexer!{self(),directory,"/d/ICBPI/profiles-dev/projects"}.'

check:
	@$(REBAR) skip_deps=true build-plt dialyze 
