# Set ER_TEST_PROJECT to a big test project (for instance a bunch of java source file....)
REBAR=./rebar3
# -s lager
# +K true enable kernel poll
ERLANG_OPTS=-sname cli -setCookie ErZaukerCluster -pa ./_build/default/lib/eredis/ebin/ -pa ./_build/default/lib/er_zauker/ebin/ +K true -smp enable  ${ERL_ARGS}
all: compile eunit help

compile:
	@$(REBAR) compile

distclean: clean
	rm $(DEPSOLVER_PLT)
	rm -rvf $(CURDIR)/deps/*

# Consider using 
# /etc/init.d/redis-server stop ; rm /var/lib/redis/dump.rdb ; /etc/init.d/redis-server start
# to cleanup your redis installation, beacuse some test can otherwise fail
eunit:
	@$(REBAR) eunit	
clean:
	@$(REBAR) clean
	rm -rf .eunit/*

cli:	compile
	erl $(ERLANG_OPTS) -eval 'er_zauker_app:startIndexer().'

pure-cli:
	rebar shell

# @$(REBAR) shell  --setcookie ErZaukerCluster --sname cli --script etc/test-indexer.escript
test-indexer: compile
	@echo $(CURDIR)/src
	erl  $(ERLANG_OPTS) -eval 'er_zauker_app:startIndexer(),er_zauker_indexer!{self(),directory,"$(CURDIR)/src/"},er_zauker_app:wait_worker_done(),init:stop().'

test-big-project: compile
	$(CURDIR)/bin/czindexer $(ER_TEST_PROJECT)


benchmark: compile
	@echo "This test will benchmark performances"
	erl $(ERLANG_OPTS) -s eprof -eval 'er_zauker_app:startIndexer(),eprof:start_profiling([self(),er_zauker_indexer,er_zauker_rpool]),er_zauker_indexer!{self(),directory,"$(ER_TEST_PROJECT)"},er_zauker_app:wait_worker_done(),eprof:stop_profiling(),eprof:log("eprof-report.log"),eprof:analyze(total),init:stop().'


test-iso: compile
	erl  $(ERLANG_OPTS) -eval 'er_zauker_app:startIndexer(),er_zauker_indexer!{self(),file,"./test_files/iso-8859-file.txt"}.'


check:
	@$(REBAR) skip_deps=true build-plt dialyze 


# see http://blog.ericbmerritt.com/2012/09/02/proper-use-of-dialyzer.html
#     https://gist.github.com/ericbmerritt/3600078

dialyzer:
	$(REBAR) dialyzer

# Monitor redis DBSIZE, memory CPU in a very light manner
# See http://en.wikipedia.org/wiki/X11_color_names for color list
monitor:
	xterm  -geometry 50x10+1 -fg cyan -fn 10x20 -e 'watch --interval 3.33 -d $(CURDIR)/bin/redis-status-snapshot.sh' &

help:
	@echo "Useful targets:"
	@echo "all              build all"
	@echo "test-big-project will index project pointed by environment variable ER_TEST_PROJECT=$(ER_TEST_PROJECT)"
	@echo "benchmark        will benchmark (via eprof) the project pointed by  ER_TEST_PROJECT (slow down things)"
	@echo "cli              will offer you a ready to use erlang shell"
	@echo "eunit            will run no regression tests"
	@echo ""
	@echo "dialyzer         do a deep type analisis. Slow on first run but will find a LOT of errors"
