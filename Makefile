.PHONY: all build run clean install

all: build

build:
	@./scripts/build_app.sh

run: build
	@echo "==> Launching MonitorSwitcher.app..."
	@open dist/MonitorSwitcher.app

install: build
	@echo "==> Installing to /Applications..."
	@rm -rf /Applications/MonitorSwitcher.app
	@cp -R dist/MonitorSwitcher.app /Applications/
	@echo " Installed to /Applications/MonitorSwitcher.app"

clean:
	@rm -rf .build dist
	@echo " Cleaned build artifacts."
