# Set ER_TEST_PROJECT to a big test project (for instance a bunch of java source file....)
REBAR=`which rebar || ./rebar`

all: deps compile
deps:
	@$(REBAR) get-deps
compile:
	@$(REBAR) --jobs 4 compile
eunit:
	@$(REBAR) --jobs 12 --verbose skip_deps=true eunit	
clean:
	@$(REBAR) clean
	rm -rf .eunit/*

cli:	compile
	erl  -name Cli -setCookie ErZaukerCli  -pa lib/eredis/ebin/ -pa ebin/ -eval 'observer:start(),er_zauker_app:startIndexer().'

test-indexer: compile
	erl  -name Cli -setCookie ErZaukerCli  -pa lib/eredis/ebin/ -pa ebin/ -eval 'er_zauker_app:startIndexer(),er_zauker_indexer!{self(),directory,"src/"}.'

test-big-project: compile
	erl  -name Cli -setCookie ErZaukerCli  -pa lib/eredis/ebin/ -pa ebin/ -eval 'er_zauker_app:startIndexer(),er_zauker_indexer!{self(),directory,"$(ER_TEST_PROJECT)"}.'

test-iso: compile
	erl  -name Cli -setCookie ErZaukerCli  -pa lib/eredis/ebin/ -pa ebin/ -eval 'er_zauker_app:startIndexer(),er_zauker_indexer!{self(),file,"./test_files/iso-8859-file.txt"}.'


check:
	@$(REBAR) skip_deps=true build-plt dialyze 
