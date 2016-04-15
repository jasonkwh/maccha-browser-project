## Maccha: A lightweight iOS web browser

[![GitHub license](https://img.shields.io/badge/license-MPL%202.0-brightgreen.svg)](https://raw.githubusercontent.com/jasonkwh/maccha-browser-project/master/LICENSE.txt)
[![Build Status](https://travis-ci.org/jasonkwh/maccha-browser-project.svg?branch=master)](https://travis-ci.org/jasonkwh/maccha-browser-project)
[![Xcode Version](https://img.shields.io/badge/xcode-7.3-blue.svg)](https://developer.apple.com/xcode/)

Maccha is intended to revolutionize the web browsing experiences on iOS phablets.

[Try the Free Demo (based on Build 219)](https://appetize.io/app/bh0knv7rhku9djeg8bh4kae61m)

## Setting up with CocoaPods

We used the latest CocoaPods to integrate our projects and third-party libraries. [CocoaPods](https://cocoapods.org/) is a dependency manager for Swift and Objective-C Cocoa projects.

You can install preview version of CocoaPods with [RubyGems](https://rubygems.org/) using the following command:

```bash
$ sudo gem install cocoapods --pre
```

Navigate to your directory by cd / mkdir commands, then use the following commands:

```bash
$ git clone https://github.com/jasonkwh/maccha-browser-project
$ cd maccha-browser-project
$ pod repo update
$ pod install
```

Lastly, open 'maccha.xcworkspace' by Xcode.
