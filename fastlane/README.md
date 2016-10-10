fastlane documentation
================
# Installation
```
sudo gem install fastlane
```
# Available Actions
### changelog
```
fastlane changelog
```
Displays the commits between working tree and the last beta/release tag
### certificates
```
fastlane certificates
```
Fetches the distribution certificates and provisioning profiles to compile the app for development & distribution
### build
```
fastlane build
```
Build production and debug build
### deploy
```
fastlane deploy
```
Submit a new version to iTunes Connect and Google Play



If on master; it will do the following: 

- Displays the commits between working tree and the last beta/release tag

- Fetches distribution certificates and provisioning profiles

- Upload screenshots + app metadata

- Build, sign and upload the app release

- Do a build version bump and push it

The application will *not* be submitted for review or automatically released



If on develop; it will do the following: 

- Displays the commits between working tree and the last beta/release tag

- Make sure the profiles are up to date and download the latest one

- Do a build version bump and push it

- Build, sign and upload the app for testing

The application will *not* be submitted for review or automatically released to external testers


### deploy_googleplay
```
fastlane deploy_googleplay
```

### devices
```
fastlane devices
```
Registers developer devices with iTunes Connect
### metadata
```
fastlane metadata
```
Upload application metadata to iTunes Connect and Google Play
### screenshots
```
fastlane screenshots
```
Upload application screenshots to iTunes Connect and Google Play

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [https://fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [GitHub](https://github.com/fastlane/fastlane/tree/master/fastlane).
