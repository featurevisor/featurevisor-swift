install:
	@echo "nothing to install for swift"

format:
	xcrun swift -version
	which swiftformat
	swiftformat --version
	swiftformat ./Sources
	swiftformat ./Tests

build:
	# make clean-swift
	# npm run generate:swift
	make format-swift
	swift build

test:
	swift test
