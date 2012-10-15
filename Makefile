COFFEEC=coffee -cp
BROWSERIFYC=browserify

COMMON_LIB = 

SERVER_LIB = \
	lib/server/application.js

CLIENT_LIB = \
	lib/client/application.js

all: common server client

common: $(COMMON_LIB)

server: common $(SERVER_LIB)

client: common $(CLIENT_LIB) lib/client/public/js/game.js

%.js:: %.coffee
	$(COFFEEC) $< >$@

lib/client/public/js/game.js: $(COMMON_LIB) $(CLIENT_LIB)
	$(BROWSERIFYC) lib/client/application.js -o $@

clean:
	rm -f $(COMMON_LIB) $(SERVER_LIB) $(CLIENT_LIB) lib/client/public/js/game.js

install: all
	cp -pr lib/client/public .

uninstall:
	rm -rf public

.PHONY: all common server client clean install uninstall