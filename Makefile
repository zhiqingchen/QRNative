.PHONY: build test run app dmg release clean brand

build:
	swift build

test:
	swift test

run:
	swift run QRNative

brand:
	./scripts/generate-brand-assets.swift

app:
	./scripts/build-app.sh

dmg:
	./scripts/build-app.sh release
	./scripts/build-dmg.sh

release:
	./scripts/generate-brand-assets.swift
	swift test
	./scripts/build-app.sh release
	ditto -c -k --keepParent .build/QRNative.app .build/QRNative-macOS.zip
	./scripts/build-dmg.sh
	./scripts/validate-dmg.sh
	shasum -a 256 .build/QRNative-macOS.zip > .build/QRNative-macOS.zip.sha256
	shasum -a 256 .build/QRNative-macOS.dmg > .build/QRNative-macOS.dmg.sha256

clean:
	rm -rf .build
