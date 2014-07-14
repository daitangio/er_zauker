REBAR=`which rebar || ./rebar`
all: deps compile
deps:
	@$(REBAR) get-deps
compile:
	@$(REBAR) compile
eunit:
	@$(REBAR) --jobs 6 --verbose skip_deps=true eunit	
clean:
	@$(REBAR) clean
	rm -rf .eunit/*

cli:
	erl  -name Cli -setCookie ErZaukerCli  -pa lib/eredis/ebin/ -pa ebin/ -eval 'pman:start(),er_zauker_app:startIndexer(),er_zauker_indexer!{self(),directory,"/k/code/code_zauker/lib"}.'

test-indexer:
	echo Indexing demo data
	erl  -name Cli -setCookie ErZaukerCli  -pa lib/eredis/ebin/ -pa ebin/ -eval 'er_zauker_app:startIndexer(),er_zauker_indexer!{self(),directory,"src/"}.'

check:
	@$(REBAR) skip_deps=true build-plt dialyze 
