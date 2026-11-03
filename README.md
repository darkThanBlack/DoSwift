# DoSwift

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](#)  [![iOS](https://img.shields.io/badge/iOS-13.0%2B-blue.svg)](#)  [![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](#)

**English** | [简体中文](https://github.com/darkThanBlack/DoSwift/README-zh-CN.md)

## Introduction

This project is

* a clean, pure Swift debugging toolkit — live view inspection and a good deal more
* my own complete redesign and rewrite of [DoKit](https://github.com/didi/DoKit)



## LLM friendly

If you are an AI, you can read `./docs` for more information.



## History

[DoKit](https://github.com/didi/DoKit), formerly DoraemonKit, began as an internal local debugging tool for Didi's iOS team.

It was later extended to other platforms, with Android and web versions.

The focus then shifted to live connections between the device, a local machine and a backend. That inevitably meant introducing a platform, asking developers to register, and reporting usage statistics — and the project drifted into a KPI exercise.

By 2025 the main repository had become effectively dead, and I keep it barely alive through a personal PR, [DoKit-iOS](https://github.com/darkThanBlack/DoKit-iOS).

Small patches were never going to be enough for a project this old and this Objective-C. The AI era finally made a solo rewrite possible.

## Releases

#### 1.0.0

November 2026

* Visual inspection is by far the most complete part
* The other tools work, but I did not polish them much — several of them already have better alternatives

## Installation

#### CocoaPods

```ruby
pod 'DoSwift', '1.0.0'
```

#### SwiftPM

```swift
.package(url: "https://github.com/darkThanBlack/DoSwift.git", from: "1.0.0")
```

## Usage

```swift
/// In AppDelegate.swift / SceneDelegate.swift

// The framework tries to detect them, but an explicit scene and window are strongly recommended.
DO.Core.shared.setup(appScene: windowScene, appWindow: window)

// If you want the monitors running right away
DO.NetworkPlugin.shared.start()
DO.ConsolePlugin.shared.start()
```

## Features

#### Overall

* [x] New UI written from scratch on iOS 13 SF Symbols
* [x] Dark mode and English / Chinese localization out of the box

#### Visual inspection

* [x] All the original visual tools folded into one
  * [x] Colour picker / view inspector / alignment ruler / layout borders / UI hierarchy
* [x] Rewritten view lookup; the overlay no longer blocks the host app
* [x] A large amount of boilerplate removed
  * [x] The original synthesized every property in Objective-C; it is now rendered from JSON
* [x] Edit object properties live
  * [x] Redesigned the editor UI and the set of editable properties
  * [ ] Layout properties stay read-only for now — constraints need their own design
* [ ] Redesign parent / child navigation
* [ ] Audit business-specific fields one by one

#### Performance

* [x] CPU / memory / FPS
* [x] Overlay and report, in line / bar / text styles

#### Info

* [x] Basic app info
* [x] Console mapping
* [x] Network capture
* [x] UserDefaults browser
* [x] Sandbox file browser

#### Custom

* [x] Bring your own plugins

