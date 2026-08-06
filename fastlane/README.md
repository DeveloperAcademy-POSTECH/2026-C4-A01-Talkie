fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios preflight

```sh
[bundle exec] fastlane ios preflight
```

Validate Talkie's release package locally without contacting Apple

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Capture the deterministic Korean App Store screenshot set

### ios asc_status

```sh
[bundle exec] fastlane ios asc_status
```

Read the Talkie record and latest TestFlight build from App Store Connect

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload Talkie to TestFlight without submitting for review

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

Upload Korean metadata only; no screenshots, binary, or review submission

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload approved screenshots only; no metadata, binary, or review submission

### ios review_precheck

```sh
[bundle exec] fastlane ios review_precheck
```

Run App Store metadata policy checks without submitting for review

### ios submit_review

```sh
[bundle exec] fastlane ios submit_review
```

Submit the selected build to App Review after explicit confirmation

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
