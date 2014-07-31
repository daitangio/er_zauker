# Set ER_TEST_PROJECT to a big test project (for instance a bunch of java source file....)
REBAR=`which rebar || ./rebar`
# -s lager
# +K true enable kernel poll
ERLANG_OPTS=-name Cli -setCookie ErZaukerCli  -pa deps/eredis/ebin/ -pa deps/eep/ebin/  -pa ebin/ +K true -smp enable -s crypto -s inets -s ssl ${ERL_ARGS}
all: deps compile
deps:
	@$(REBAR) get-deps
compile:
	@$(REBAR) --jobs 8 compile
eunit:
	@$(REBAR) --jobs 12 --verbose skip_deps=true eunit	
clean:
	@$(REBAR) clean
	rm -rf .eunit/*

cli:	compile
	erl $(ERLANG_OPTS) -eval 'observer:start(),er_zauker_app:startIndexer().'

test-indexer: compile
	erl  $(ERLANG_OPTS) -eval 'er_zauker_app:startIndexer(),er_zauker_indexer!{self(),directory,"src/"},er_zauker_app:wait_worker_done(),init:stop().'

test-big-project: compile
	erl $(ERLANG_OPTS) -eval 'er_zauker_app:startIndexer(),er_zauker_indexer!{self(),directory,"$(ER_TEST_PROJECT)"},er_zauker_app:wait_worker_done(),init:stop().'



benchmark: compile
	@echo "This test will benchmark performances"
	erl $(ERLANG_OPTS) -s eprof -eval 'eprof:start_profiling([self()]),er_zauker_app:startIndexer(),er_zauker_indexer!{self(),directory,"$(ER_TEST_PROJECT)"},er_zauker_app:wait_worker_done(),eprof:stop_profiling(),eprof:analyze(total).'


test-iso: compile
	erl  $(ERLANG_OPTS) -eval 'er_zauker_app:startIndexer(),er_zauker_indexer!{self(),file,"./test_files/iso-8859-file.txt"}.'


check:
	@$(REBAR) skip_deps=true build-plt dialyze 
