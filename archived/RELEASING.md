Release Process
===============

 1.  Ensure `version` in `SwiftPhoenixClient.podsec` is set to the version you want to release.
 2.  Run a trial pod release `pod lib lint`
 3.  Update `CHANGELOG.md` with the version about to be released along with notes.
 4.  Commit: `git commit -am "Prepare version X.Y.X"`
 5.  Tag: `git tag -a X.Y.Z -m "Version X.Y.Z"`
 6.  Push: `git push && git push --tags`
 7.  Release to Cocoapods `pod trunk push SwiftPhoenixClient.podspec`
 8.  Add the new release with notes (https://github.com/davidstump/SwiftPhoenixClient/releases).