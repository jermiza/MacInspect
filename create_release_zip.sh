#!/bin/bash

# Exit on error
set -e

echo "=== Cleaning previous builds ==="
rm -rf build
rm -f MacInspect.zip

echo "=== Building MacInspect in Release configuration ==="
xcodebuild -project MacInspect.xcodeproj \
           -scheme MacInspect \
           -configuration Release \
           -derivedDataPath build \
           -destination 'platform=macOS' \
           build

echo "=== Packaging application into MacInspect.zip ==="
cd build/Build/Products/Release
zip -r ../../../../MacInspect.zip MacInspect.app

cd ../../../../
echo "=== Done! ==="
echo "Your production release archive is ready at: ./MacInspect.zip"
echo ""
echo "To publish on GitHub:"
echo "1. Push your latest commits to GitHub."
echo "2. Go to your repository page -> Releases -> Draft a new release."
echo "3. Drag and drop the created 'MacInspect.zip' into the binaries attachment box."
echo "4. Publish the release!"
