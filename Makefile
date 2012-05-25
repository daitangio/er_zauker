REBAR=`which rebar || ./rebar`
all: deps compile
deps:
	@$(REBAR) get-deps
compile:
	@$(REBAR) compile

test:
	@$(REBAR) skip_deps=true eunit

clean:
	@$(REBAR) clean
pack:
	echo Gioorgi Pack
	tar jcvf ../theConsultantLatest.tar.bz2 --exclude=.hg/\* --exclude=.git/\* .

