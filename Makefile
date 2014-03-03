REBAR=`which rebar || echo ./rebar`
DIALYZER = dialyzer

all: 
	@$(REBAR) get-deps

get-deps:
	@$(REBAR) get-deps

compile:
	@$(REBAR) compile

clean:
	
	@$(REBAR) clean
	rm -Rf deps

tests: eunit ct

eunit:
	@$(REBAR) skip_deps=true eunit

ct:
	@$(REBAR) skip_deps=true ct

check: xref dialyzer 

xref:
	@$(REBAR) skip_deps=true xref

dialyzer:
	@$(DIALYZER) -q -n -I include --src src/*.erl -Werror_handling \
		-Wrace_conditions -Wno_return # -Wunmatched_returns -Wunderspecs

docs:
	@$(REBAR) doc
