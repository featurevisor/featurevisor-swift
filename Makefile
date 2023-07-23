install:
	@echo "nothing to install for swift"

format:
	xcrun swift -version
	which swift-format
	swift-format --version
	swift-format format -i -r ./Sources
	swift-format format -i -r ./Tests

build:
	make clean-swift
	npm run generate:swift
	make format-swift
	swift build

test:
	swift test
