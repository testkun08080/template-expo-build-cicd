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

### ios certificates

```sh
[bundle exec] fastlane ios certificates
```

Sync certificates from match (readonly)

### ios certificates_renew

```sh
[bundle exec] fastlane ios certificates_renew
```

Create or renew certificates in match (admin only)

### ios build

```sh
[bundle exec] fastlane ios build
```

Prebuild, sign, and create an App Store .ipa

### ios upload

```sh
[bundle exec] fastlane ios upload
```

Upload an existing .ipa to TestFlight

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload to TestFlight

----


## Android

### android build

```sh
[bundle exec] fastlane android build
```

Prebuild, restore keystore, and create a release app bundle

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
