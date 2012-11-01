COFFEEC=coffee -cp
BROWSERIFYC=browserify

COMMON_LIB = \
	lib/common/EventEmitter.js

SERVER_LIB = \
	lib/server/Server.js

CLIENT_LIB = \
	lib/client/Sprite.js \
	lib/client/World.js \
	lib/client/Player.js \
	lib/client/Client.js

all: common server client

common: $(COMMON_LIB)

server: common $(SERVER_LIB)

client: common $(CLIENT_LIB) lib/client/public/js/Client.js

%.js:: %.coffee
	$(COFFEEC) $< >$@

lib/client/public/js/Client.js: $(COMMON_LIB) $(CLIENT_LIB)
	$(BROWSERIFYC) lib/client/Client.js -o $@

clean:
	rm -f $(COMMON_LIB) $(SERVER_LIB) $(CLIENT_LIB) lib/client/public/js/game.js

install: all
	cp -pr lib/client/public ./dist

uninstall:
	rm -rf dist

.PHONY: all common server client clean install uninstall