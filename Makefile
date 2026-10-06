FREEDOOM_VERSION := 0.13.0
FREEDOOM_ZIP := doomgeneric/freedoom-$(FREEDOOM_VERSION).zip
GUS_PATCH_REV := 7b8fc9241650420530b883803889f8bf88279d2e
GUS_PATCH_ZIP := doomgeneric/dgguspat-$(GUS_PATCH_REV).zip

.PHONY: all wasm clean serve
all: wasm

doomgeneric/freedoom1.wad:
	curl -fL https://github.com/freedoom/freedoom/releases/download/v$(FREEDOOM_VERSION)/freedoom-$(FREEDOOM_VERSION).zip -o $(FREEDOOM_ZIP)
	unzip -o $(FREEDOOM_ZIP) freedoom-$(FREEDOOM_VERSION)/freedoom1.wad -d doomgeneric
	mv doomgeneric/freedoom-$(FREEDOOM_VERSION)/freedoom1.wad $@
	rmdir doomgeneric/freedoom-$(FREEDOOM_VERSION)

doomgeneric/dgguspat/acpiano.pat:
	curl -fL https://github.com/redddcyclone/dgguspat/archive/$(GUS_PATCH_REV).zip -o $(GUS_PATCH_ZIP)
	unzip -q $(GUS_PATCH_ZIP) -d doomgeneric
	mv doomgeneric/dgguspat-$(GUS_PATCH_REV)/dgguspat doomgeneric/dgguspat
	{ echo 'dir /dgguspat'; cat doomgeneric/dgguspat-$(GUS_PATCH_REV)/timidity.cfg; } > doomgeneric/timidity.cfg
	rm -rf doomgeneric/dgguspat-$(GUS_PATCH_REV)

wasm: doomgeneric/freedoom1.wad doomgeneric/dgguspat/acpiano.pat
	$(MAKE) -C doomgeneric -f Makefile.emscripten

clean:
	$(MAKE) -C doomgeneric -f Makefile.emscripten clean
	rm -f doomgeneric/freedoom1.wad $(FREEDOOM_ZIP) doomgeneric/timidity.cfg $(GUS_PATCH_ZIP)
	rm -rf doomgeneric/dgguspat

serve: wasm
	python3 -m http.server 8000
