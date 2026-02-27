.PHONY: all format analyze test publish-dry-run publish

all: format analyze test

format:
	dart format .

analyze:
	dart analyze .

test:
	cd packages/analyzer_kit_annotation && dart test
	cd packages/analyzer_kit && dart test

publish-dry-run:
	cd packages/analyzer_kit_annotation && dart pub publish --dry-run
	cd packages/analyzer_kit && dart pub publish --dry-run

publish:
	cd packages/analyzer_kit_annotation && dart pub publish
	cd packages/analyzer_kit && dart pub publish
