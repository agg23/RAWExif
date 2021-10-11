# RAWExif
## Tool for EXIF operations on Apple Photos

RAWExif is a simple SwiftUI tool to manipulate Apple (iCloud) Photos. By default it will download and losslessly apply lens EXIF data changes to the "original" photo representation in Apple Photos (if you uploaded RAW photos, this will be RAW, otherwise it's typically a JPEG). This is useful both for archiving operations, and for "fixing" EXIF data for manual/vintage lenses.

Additionally, the app supports uploading new JPEGs (losslessly created) from the provided lens EXIF data back to Apple Photos. This supports workflows such as uploading RAW directly from your camera, editing in iOS apps that integrate with Apple Photos, exporting the original RAWs (with updated EXIF lens data), then replacing the large RAW files with smaller JPEGs in Apple Photos for consumption.

Future work will allow editing of local photos as well.

![RAWExif Main Screen](https://user-images.githubusercontent.com/238679/136835689-6dca8369-f51c-40c0-8525-6ab980f2e939.png)

### Licensing

RAWExif is licensed under the MIT license. For convenience, the wonderful [`exiftool` library](https://exiftool.org/) is included in this repo, licensed under the "Artistic License".
