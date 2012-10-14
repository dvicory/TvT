COFFEEC=coffee -cp
BROWSERIFYC=browserify

COMMON_LIB = 

SERVER_LIB = \
	lib/server/application.jsc

CLIENT_LIB = \
	lib/client/application.jsc

all: $(COMMON_LIB) lib/client/public/js/game.jsc $(SERVER_LIB)

%.jsc:: %.coffee
	$(COFFEEC) $< >$@

lib/client/public/js/game.jsc: $(CLIENT_LIB) $(COMMON_LIB)
	$(BROWSERIFYC) lib/client/application.jsc -o $@

clean:
	rm -f $(COMMON_LIB) $(SERVER_LIB) $(CLIENT_LIB)

install: all
	cp -pr lib/client/public .

uninstall:
	rm -rf public

.PHONY: all clean install uninstall