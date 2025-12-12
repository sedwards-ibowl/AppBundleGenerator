# GitHub Actions Workflows

## build-and-release.yml

This workflow handles building, testing, and releasing AppBundleGenerator for macOS.

### Triggers

- **Push to master**: Builds and runs tests on every commit to master
- **Pull requests**: Validates PRs before merging
- **Tags (v\*.\*.\*)**: Creates GitHub releases when you push version tags
- **Manual**: Can be triggered manually from the Actions tab

### Jobs

#### 1. Build Job
Runs on: `macos-12`

- Checks out code
- Sets up Xcode environment
- Checks for deprecated APIs
- Builds the binary with `make`
- Runs smoke tests:
  - Creates a test bundle
  - Validates Info.plist format
  - Verifies bundle structure
- Packages binary as `.tar.gz`
- Uploads artifacts

#### 2. Release Job
Runs on: `ubuntu-latest` (only for tags)

- Downloads build artifacts
- Extracts changelog for the version
- Creates GitHub Release with:
  - Binary tarball
  - Release notes from CHANGELOG.md
  - Installation instructions
  - Checksums

#### 3. Test Advanced Features Job
Runs on: `macos-12`

- Tests icon conversion (PNG → ICNS)
- Tests custom bundle options (identifier, category, version)
- Tests ad-hoc code signing with hardened runtime
- Verifies signatures with `codesign`

### Creating a Release

1. Update version in your code if needed
2. Update CHANGELOG.md with version notes
3. Create and push a version tag:

```bash
git tag -a v2.0.0 -m "Release version 2.0.0"
git push origin v2.0.0
```

4. GitHub Actions will automatically:
   - Build the binary on macOS
   - Run all tests
   - Create a GitHub Release
   - Upload the binary as a downloadable asset

### Release Artifacts

Each release includes:

- `AppBundleGenerator-{version}-macos.tar.gz` - Versioned binary
- `AppBundleGenerator-macos.tar.gz` - Latest build artifact
- Release notes extracted from CHANGELOG.md

### Local Testing

To test the workflow locally before pushing:

```bash
# Run the same build steps
make info
make check-deprecated
make clean && make

# Run smoke tests
./AppBundleGenerator 'Test' /tmp '/bin/echo Test'
plutil -lint "/tmp/Test.app/Contents/Info.plist"

# Test icon conversion
./AppBundleGenerator --icon icon.png 'Test' /tmp '/bin/echo Test'

# Test code signing
./AppBundleGenerator --sign - --hardened-runtime 'Test' /tmp '/bin/echo Test'
codesign --verify --verbose=2 "/tmp/Test.app"
```

### Workflow Status

Check the status of your workflows at:
`https://github.com/{username}/AppBundleGenerator/actions`

### Troubleshooting

**Build fails with "command not found: clang"**
- The macOS runner should have Xcode pre-installed
- Check the setup-xcode step configuration

**Tests fail with icon conversion errors**
- Icon tests gracefully skip if icon creation fails
- Check that `sips` and `iconutil` are available on the runner

**Release not created for tag**
- Ensure tag follows format: `v*.*.*` (e.g., v2.0.0, v1.5.3)
- Check that GITHUB_TOKEN has write permissions
- Verify the release job has `permissions: contents: write`

**Changelog extraction fails**
- Workflow will use generic release notes if CHANGELOG.md is missing
- Format your CHANGELOG with sections like:
  ```
  ## [2.0.0] - 2025-01-15
  - Feature: Added icon conversion
  - Fix: Resolved signing issues
  ```
