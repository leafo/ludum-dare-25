.PHONY: build run run43 deploy clean

LOVE_VERSION = 11.5
LOVE_FILE = x-moon-love$(LOVE_VERSION).love
ITCH_TARGET = leafo/x-moon:love-$(LOVE_VERSION)
USER_VERSION = love$(LOVE_VERSION)-$(shell git rev-parse --short HEAD)

build:
	moonc *.moon lovekit/*.moon

run: build
	love .

# 4:3 handheld resolution (RG35XX)
run43: build
	love . --window 640x480

$(LOVE_FILE): build
	rm -f $(LOVE_FILE)
	zip -9 -r $(LOVE_FILE) *.lua img sounds lovekit/*.lua

deploy: $(LOVE_FILE)
	butler push $(LOVE_FILE) $(ITCH_TARGET) --userversion $(USER_VERSION)

clean:
	rm -f $(LOVE_FILE)
