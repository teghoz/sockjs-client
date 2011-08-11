.PHONY: all build tests test

all: sockjs.js

build: sockjs.js sockjs.min.js sockjs.pretty.js

sockjs.js: lib/*js
	coffee bin/render.coffee lib/all.js > $@

sockjs.min.js: lib/*js
	coffee bin/render.coffee --minify lib/all.js > $@

sockjs.pretty.js: lib/*js
	coffee bin/render.coffee --minify --pretty lib/all.js > $@

tests/html/lib/sockjs.js: sockjs.js
	cp $< $@

tests/html/lib/tests.js: tests/html/src/tests.coffee
	coffee -o tests/html/lib/ -c --bare $<

test: tests
tests: tests/html/lib/sockjs.js tests/html/lib/tests.js
	node tests/server.js


serve:
	@if [ -e .pidfile.pid ]; then			\
		kill `cat .pidfile.pid`;		\
		rm .pidfile.pid;			\
	fi

	@while [ 1 ]; do				\
	        echo " [*] Running http server";	\
	        make test &				\
	        SRVPID=$$!;				\
	        echo $$SRVPID > .pidfile.pid;		\
	        echo " [*] Server pid: $$SRVPID";	\
	    inotifywait -r -q -e modify .;		\
	    kill `cat .pidfile.pid`;			\
	    rm -f .pidfile.pid;				\
	    sleep 0.1;					\
	done

VER:=$(shell ./VERSION-GEN)
upload: build
	[ -e ../sockjs-client-gh-pages ] || 				\
		git clone `git remote -v|tr "[:space:]" "\t"|cut -f 2`	\
			--branch gh-pages ../sockjs-client-gh-pages
	(cd ../sockjs-client-gh-pages; git pull;)
	for f in sock*js; do						\
		cp $$f ../sockjs-client-gh-pages/`echo $$f|sed 's|\(sockjs\)\(.*[.]js\)|\1-$(VER)\2|g'`; \
	done
	(cd ../sockjs-client-gh-pages; node generate_index.js > index.html;)