Release Process
===============

 1.  Update `CHANGELOG.md` with the version about to be released along with notes.
 2.  Commit: `git commit -am "Prepare version X.Y.X"`
 3.  Tag: `git tag -a X.Y.Z -m "Version X.Y.Z"`
 4.  Push: `git push && git push --tags`
 5.  Add the new release with notes (https://github.com/davidstump/SwiftPhoenixClient/releases).
