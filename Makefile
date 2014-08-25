# Set ER_TEST_PROJECT to a big test project (for instance a bunch of java source file....)
REBAR=`which rebar || ./rebar`
# -s lager
# +K true enable kernel poll
ERLANG_OPTS=-name Cli -setCookie ErZaukerCli  -pa deps/*/ebin/ -pa ebin/ +K true -smp enable  ${ERL_ARGS}
all: get-deps compile help
get-deps:
	@$(REBAR) get-deps
compile:
	@$(REBAR) --jobs 8 compile

# Consider using 
# /etc/init.d/redis-server stop ; rm /var/lib/redis/dump.rdb ; /etc/init.d/redis-server start
# to cleanup your redis installation, beacuse some test can otherwise fail
eunit:
	@$(REBAR) --jobs 12 --verbose skip_deps=true eunit	
clean:
	@$(REBAR) clean
	rm -rf .eunit/*

cli:	compile
	erl $(ERLANG_OPTS) -eval 'er_zauker_app:startIndexer().'

pure-cli:
	rebar shell

test-indexer: compile
	erl  $(ERLANG_OPTS) -eval 'er_zauker_app:startIndexer(),er_zauker_indexer!{self(),directory,"src/"},er_zauker_app:wait_worker_done(),init:stop().'

test-big-project: compile
	erl $(ERLANG_OPTS) -eval 'er_zauker_app:startIndexer(),er_zauker_indexer!{self(),directory,"$(ER_TEST_PROJECT)"},er_zauker_app:wait_worker_done(),init:stop().'



benchmark: compile
	@echo "This test will benchmark performances"
	erl $(ERLANG_OPTS) -s eprof -eval 'er_zauker_app:startIndexer(),eprof:start_profiling([self(),er_zauker_indexer,er_zauker_rpool]),er_zauker_indexer!{self(),directory,"$(ER_TEST_PROJECT)"},er_zauker_app:wait_worker_done(),eprof:stop_profiling(),eprof:log("eprof-report.log"),eprof:analyze(total),init:stop().'


test-iso: compile
	erl  $(ERLANG_OPTS) -eval 'er_zauker_app:startIndexer(),er_zauker_indexer!{self(),file,"./test_files/iso-8859-file.txt"}.'


check:
	@$(REBAR) skip_deps=true build-plt dialyze 


help:
	@echo "Useful targets:"
	@echo "all              build all"
	@echo "test-big-project will index project pointed by environment variable ER_TEST_PROJECT=$(ER_TEST_PROJECT)"
	@echo "benchmark        will benchmark (via eprof) the project pointed by  ER_TEST_PROJECT (slow down things)"
	@echo "cli              will offer you a ready to use erlang shell"
	@echo "eunit            will run no regression tests"
