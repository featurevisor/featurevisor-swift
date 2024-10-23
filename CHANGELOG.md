# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## [1.0.3](https://github.com/featurevisor/featurevisor-swift/compare/1.0.2...1.0.3) (2024-10-23)

### Refactor

* refactor: Convert codables to directory under a separate thread [cd613b5](https://github.com/featurevisor/featurevisor-swift/commit/cd613b5e072c2359c636475b4efc4dffa07f2dd1)
* refactor: Remove redundant async when refreshing[6ffc416](https://github.com/featurevisor/featurevisor-swift/commit/6ffc4167d05b3934a8f82f7a0a49c02d72eec7a8)

## [1.0.2](https://github.com/featurevisor/featurevisor-swift/compare/1.0.1...1.0.2) (2024-07-22)

### Refactor

* refactor: Rename FeaturevisorCLI to Featurevisor [30415b7](https://github.com/featurevisor/featurevisor-swift/pull/73/commits/30415b7afe94cf07f27f75873f6f3a26bf6ada2e)


## [1.0.1](https://github.com/featurevisor/featurevisor-swift/compare/1.0.0...1.0.1) (2024-07-17)

### Refactor

* Refactor logger message when datafile fetching finished with error [554d96b](https://github.com/featurevisor/featurevisor-swift/commit/554d96b86da8d22554f9a6d40ab99121aae9504a)

## [1.0.0](https://github.com/featurevisor/featurevisor-swift/compare/0.9.0...1.0.0) (2024-07-10)

### Refactor

* refactor: Rename FeaturevisorTestRunner to FeaturevisorCLI [134835b](https://github.com/featurevisor/featurevisor-swift/pull/73/commits/134835b1c3e457f0fca4bfcd4fd476578e1707f7)

## [0.9.0](https://github.com/featurevisor/featurevisor-swift/compare/0.8.0...0.9.0) (2024-05-06)

### Features

* evaluate features in CLI ([69fdb0e](https://github.com/featurevisor/featurevisor-swift/commit/69fdb0ec3fd8b029d689669553e18558b1f7e0f7))
* benchmarking option in CLI ([3d6eb94](https://github.com/featurevisor/featurevisor-swift/commit/3d6eb941f5d5d7ce0845d32b6ada23cde2274d83))

### Refactor
* 
* make datafile handler async ([9886301](https://github.com/featurevisor/featurevisor-swift/commit/988630114365303c1e16f1f06853ed8ca4d9df2e))

## [0.8.0](https://github.com/featurevisor/featurevisor-swift/compare/0.7.0...0.8.0) (2024-04-03)

### Features

* extend test runner assertion output + simple duration execution ([db24373](https://github.com/featurevisor/featurevisor-swift/commit/db243731c715d92a70b9a92ccbae2f6f33aed5b4))
* extend test runner with --only-failures option ([b81d4f9](https://github.com/featurevisor/featurevisor-swift/commit/b81d4f926fa0327f54e5996f578a165f5879041e))

### Refactor

* performance tweaks under DatafileReader ([c55bbbe](https://github.com/featurevisor/featurevisor-swift/commit/c55bbbe1721cd2bff1d813c2ada7b8e07a8dada4))
* remove redundant 'equatable' for VariableValue under tests ([4930eff](https://github.com/featurevisor/featurevisor-swift/commit/4930effad385a77f1b9770f64ca32a820d157162))

## [0.7.0](https://github.com/featurevisor/featurevisor-swift/compare/0.6.0...0.7.0) (2024-03-05)

### Features

* Featurevisor Swift Test Runner ([4d91882](https://github.com/featurevisor/featurevisor-swift/commit/4d918822e52a83a40efb6c086900de87bb918a0e))

## [0.6.0](https://github.com/featurevisor/featurevisor-swift/compare/0.5.0...0.6.0) (2024-02-23)

### Bugfixs

* Wrong negation under allGroupSegmentsAreMatched for 'not' operator ([785984e](https://github.com/featurevisor/featurevisor-swift/commit/785984e9583b7b04eed10ad55c9687ae29ab4bb4))
* Rule percentage checks are now inclusive of end range ([7be4657](https://github.com/featurevisor/featurevisor-swift/commit/7be4657674a960ca252ce32b72930398cbf91028))

## [0.5.0](https://github.com/featurevisor/featurevisor-swift/compare/0.4.0...0.5.0) (2024-01-09)

### Bugfixs

*  Wrong parsing datafile for segments if defined as pure string ([a47d430](https://github.com/featurevisor/featurevisor-swift/commit/a47d4309aa0edbc9cea6b6c394f974e2da59fbc1))

## [0.4.0](https://github.com/featurevisor/featurevisor-swift/compare/0.3.0...0.4.0) (2024-01-04)

### Bugfixs

*  Forcing variation with variable overrides ([4b96ae7](https://github.com/featurevisor/featurevisor-swift/commit/4b96ae7f63823b0840ab9ed646b275bfc3671774))

## [0.3.0](https://github.com/featurevisor/featurevisor-swift/compare/0.2.0...0.3.0) (2023-12-01)

### Refactor

*  Make `init` for `Feature` object public  ([f14580b](https://github.com/featurevisor/featurevisor-swift/commit/f14580b1e1a67599b20d392e315831bc6ea7bd5a))

## [0.2.0](https://github.com/featurevisor/featurevisor-swift/compare/0.1.0...0.2.0) (2023-11-10)

### Bug Fixes

*  missing operator in and notIn for string attribute and values condition ([891910f](https://github.com/featurevisor/featurevisor-swift/commit/891910f6806e0cb3f5f6fad6cb1a67fb493842ea))

## 0.1.0 (2023-10-31)

### Features