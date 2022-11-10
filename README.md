# MessagePack

A [MessagePack](https://msgpack.org/) encoder and decoder for `Codable` types.

This functionality is discussed in Chapter 7 of
[Flight School Guide to Swift Codable](https://flight.school/books/codable).

## Requirements

- Swift 5.5+

## Usage

### Encoding Messages

```swift
import MessagePack

let encoder = MessagePackEncoder()
let value = try! encoder.encode(["a": 1, "b": 2, "c": 3])
// [0x83, 0xA1, 0x62, 0x02, 0xA1, 0x61, 0x01, 0xA1, 0x63, 0x03]
```

### Decoding Messages

```swift
import MessagePack

let decoder = MessagePackDecoder()
let data = Data([0xCB, 0x40, 0x09, 0x21, 0xF9, 0xF0, 0x1B, 0x86, 0x6E])
let value = try! decoder.decode(Double.self, from: data)
// 3.14159
```

## Installation

### Swift Package Manager

Add the MessagePack package to your target dependencies in `Package.swift`:

```swift
import PackageDescription

let package = Package(
  name: "YourProject",
  dependencies: [
    .package(
        url: "git@github.com:ArtProcessors/ap-messagepack-swift.git",
        from: "1.3.0"
    ),
  ]
)
```

Then run the `swift build` command to build your project.

## License

MIT

## Contact

Mattt ([@mattt](https://twitter.com/mattt))
