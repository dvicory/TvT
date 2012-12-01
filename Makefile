COFFEEC=coffee -cp
BROWSERIFYC=browserify

COMMON_LIB = \
	lib/common/EventEmitter.js \
	lib/common/WorldObject.js \
	lib/common/StaticWorldObject.js \
	lib/common/DynamicWorldObject.js \
	lib/common/Projection.js \
	lib/common/Rectangle.js \
	lib/common/RotatedRectangle.js \
	lib/common/World.js \
	lib/common/Player.js

SERVER_LIB = \
	lib/server/Protocol.js \
	lib/server/World.js \
	lib/server/Player.js \
	lib/server/Server.js

CLIENT_LIB = \
	lib/client/Protocol.js \
	lib/client/Camera.js \
	lib/client/StaticSprite.js \
	lib/client/DynamicSprite.js \
	lib/client/World.js \
	lib/client/LocalPlayer.js \
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
	cp vendor/pulse/build/bin/*.js vendor/pulse/build/bin/modules/*.js ./dist/js

uninstall:
	rm -rf dist

.PHONY: all common server client clean install uninstall
