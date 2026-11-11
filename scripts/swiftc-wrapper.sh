#!/bin/bash
exec /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-cache-path /tmp/swift-cache "$@"
