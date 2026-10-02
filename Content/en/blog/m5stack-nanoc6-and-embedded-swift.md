---
title: Running the M5Stack NanoC6 with Embedded Swift
description: Blinking the LED on an M5Stack NanoC6 with esp32-led-blink-sdk, a sample project for Embedded Swift.
keywords: ["Swift", "ESP32-C6", "Embedded Swift"]
genre: Embedded Swift
date: "2025/1/14"
---
# Running the M5Stack NanoC6 with Embedded Swift
In this article, I use esp32-led-blink-sdk, a sample project for Embedded Swift, to blink the LED on an M5Stack NanoC6.
![M5Stack NanoC6](/images/m5stacknanoc6.png "M5Stack NanoC6")
Source : [NanoC6 - m5-docs - M5Stack](https://docs.m5stack.com/ja/core/M5NanoC6)
## Introduction
Embedded Swift was introduced at WWDC2024, and Swift is becoming usable not only for Apple devices but also for embedded devices. However, at the time of writing it has not been officially released, and you need to install a Swift DEVELOPMENT SNAPSHOT to use it.
So I decided to step outside my usual Apple-device development and try embedded development. My goal this time is **to blink the LED on an M5Stack NanoC6**. This is my first time doing embedded development, so there may be mistakes, and I appreciate your understanding.

## What is Embedded Swift?
Embedded Swift is a way to write programs for embedded devices in Swift. Unlike regular Swift, it is built with a dedicated Embedded Swift compilation mode. As a result, the available libraries and other dependencies are quite different, but most of the Swift syntax can be used as is. Conversely, some syntax cannot be used.
It drew a lot of attention with the WWDC 2024 session ["Go small with Embedded Swift"](https://developer.apple.com/videos/play/wwdc2024/10197/), but it had already been introduced earlier in the Swift.org blog posts ["Byte-sized Swift: Building Tiny Games for the Playdate"](https://www.swift.org/blog/byte-sized-swift-tiny-games-playdate/) and ["Get Started with Embedded Swift on ARM and RISC-V Microcontrollers"](https://www.swift.org/blog/embedded-swift-examples/).
As the title of the latter post suggests, Embedded Swift does not work on every embedded device; it targets microcontrollers with ARM and RISC-V architectures. If you want to develop with Embedded Swift, you need a device that supports it.

## How to choose an embedded device
### Choose by microcontroller
Whether a device supports Embedded Swift depends on its microcontroller (the chip that contains the CPU), so when choosing a device, check its microcontroller. There are probably other microcontrollers that work, but here I list only those confirmed to work in the sample projects.
- ARM
  - STM32F746
  - RP2040 (introduced in the samples as the Raspberry Pi Pico, which uses it)
  - nRF52840
- RISC-V
  - ESP32-C6

Choosing from this list should be safe. With knowledge of embedded development, such as setting up the environment and C libraries, you might be able to use other microcontrollers too, but I don't know enough to say yet.
### Why I chose the M5Stack NanoC6
This time I use the M5Stack NanoC6, which has an ESP32-C6. The rest of this article assumes the ESP32-C6, so it may not apply as is to other microcontrollers.

## Setting up the environment
Next, set up the environment. I basically follow the macOS setup steps in [Swift Matter Examples Tutorials](https://apple.github.io/swift-matter-examples/tutorials/swiftmatterexamples/setup-macos/).

First, install Xcode and the latest Swift DEVELOPMENT SNAPSHOT.

Next, check in Terminal that the snapshot is installed, and look up its CFBundleIdentifier value. You will set this value to the TOOLCHAINS environment variable later. The output below is an example, but yours should look similar.
It is also a good idea to check that the `Target` in the output of the last `swift --version` command matches your Mac's architecture (arm64 for Apple silicon).
```zsh
$ ls ~/Library/Developer/Toolchains/
swift-DEVELOPMENT-SNAPSHOT-2024-06-03-a.xctoolchain
swift-latest.xctoolchain

$ plutil -extract CFBundleIdentifier raw \
  -o - \
  ~/Library/Developer/Toolchains/swift-DEVELOPMENT-SNAPSHOT-2024-06-03-a.xctoolchain/Info.plist
org.swift.59202406031a

$ TOOLCHAINS=org.swift.59202406031a swift --version
Apple Swift version 6.0-dev (LLVM c7c87ee42989d4b, Swift 0aa0687fe0f4047)
Target: arm64-apple-macosx14.0
```
I will skip how to install Homebrew. Use Homebrew to install cmake, ninja and dfu-util.
```zsh
$ brew install cmake ninja dfu-util
```
Next, create an esp folder in your home directory, then clone esp-idf and esp-matter into it and install them.
After that, set the TOOLCHAINS environment variable to the CFBundleIdentifier value you checked earlier, and finally run each export.sh.
Note that I install esp-matter here because the tutorial does, but this sample project does not seem to use it, so it may not be necessary (I have not verified this).
```zsh
$ mkdir -p ~/esp

$ cd ~/esp
$ git clone \
  --branch v5.2.1 \
  --depth 1 \
  --shallow-submodules \
  --recursive https://github.com/espressif/esp-idf.git \
  --jobs 24

$ cd ~/esp/esp-idf
$ ./install.sh

$ cd ~/esp
$ git clone \
    --branch release/v1.2 \
    --depth 1 \
    --shallow-submodules \
    --recursive https://github.com/espressif/esp-matter.git \
    --jobs 24

$ cd ~/esp/esp-matter
$ ./install.sh

$ export TOOLCHAINS=org.swift.59202406031a

$ . ~/esp/esp-idf/export.sh

$ . ~/esp/esp-matter/export.sh
```
Then clone [swift-embedded-examples](https://github.com/apple/swift-embedded-examples), which contains the sample projects, create a Python virtual environment in that folder, and install the required packages. Replace `<path to swift-embedded-examples>` with the path to your clone of swift-embedded-examples.
```zsh
$ git clone https://github.com/apple/swift-embedded-examples.git
$ cd <path to swift-embedded-examples>
$ python3 -m venv .venv
$ source .venv/bin/activate
$ python3 -m pip install -r Tools/requirements.txt
```
The environment is now ready.

## Checking the file structure of the sample project
Before running it, let's look at how the Swift project is organized, going through the files of esp32-led-blink-sdk one by one.
- main
  - BridgingHeader.h
  A C header file. Whatever is imported here can be used from Swift.
  - CMakeLists.txt
  Defines the build settings for main. This is also where Swift is enabled.
  - idf_component.yml
  Defines the dependencies on ESP-IDF components. Nothing is listed in it this time.
  - Led.swift
  Defines the LED struct. Notice that the functions called here are not defined on the Swift side. They are defined in C libraries and made available through BridgingHeader.h.
  - Main.swift
  The entry point.
- CMakeLists.txt
  `include($ENV{IDF_PATH}/tools/cmake/project.cmake)` stands out. It seems to register components so that ESP-IDF can be used, but for now I treat it as a magic incantation.
- dependencies.lock
  Records the resolved dependencies. Since it records that esp32c6 is the target, it apparently does not need to be listed in idf_component.yml.
- diagram.json
  A JSON file that defines the board type and wiring for Wokwi, a board simulator. If you install the Wokwi extension in Visual Studio Code, you can see the board on screen. This project shows an [ESP32-C6-BUG](https://www.mouser.jp/ProductDetail/Prokyber/ESP32-C6-BUG?qs=ZcfC38r4Pou1X3IbFvgUPQ%3D%3D&srsltid=AfmBOooiRK2CNlgGq1oGmTfcpbewYg8Pd-TurtD67HyhEXK8YB_cZg8-) board. I don't use the simulator this time, so I won't go into it.
- sdkconfig
  The ESP-IDF configuration file. According to the comments in the file, it appears to be auto-generated.
- sdkconfig.old
  A previous version of sdkconfig. It also appears to be auto-generated.
- wokwi.toml
  The configuration file for Wokwi.

### What the file structure tells us
This project is notable for building with ESP-IDF's CMake rather than the Swift Package Manager. On the other hand, [swift-playdate-examples](https://github.com/apple/swift-playdate-examples), which also uses Embedded Swift, does use the Swift Package Manager. Whether an ESP32-C6 project can also be structured around the Swift Package Manager is something I'd like to look into.

## Running the sample project
Now let's run the sample project and blink the LED. The M5Stack NanoC6 has an ESP32-C6, so I use esp32-led-blink-sdk, which targets the ESP32-C6.
Connect the board to your Mac and run the following commands.
```zsh
$ cd esp32-led-blink-sdk
$ export TOOLCHAINS=org.swift.59202406031a
$ . <path-to-esp-idf>/export.sh
$ idf.py set-target esp32c6
$ idf.py build
$ idf.py flash
```
### The LED does not blink as is
The build and flash succeed, but the LED does not blink. This is because the sample project is written for a different board, the [ESP32-C6-BUG](https://www.mouser.jp/ProductDetail/Prokyber/ESP32-C6-BUG?qs=ZcfC38r4Pou1X3IbFvgUPQ%3D%3D&srsltid=AfmBOooiRK2CNlgGq1oGmTfcpbewYg8Pd-TurtD67HyhEXK8YB_cZg8-).
Check the [M5Stack NanoC6 documentation](https://docs.m5stack.com/ja/core/M5NanoC6), paying attention to the pin map.
![M5Stack NanoC6 Pinmap](/images/m5stacknanoc6-pinmap.png "Pinmap")
Source : [NanoC6 - m5-docs - M5Stack](https://docs.m5stack.com/ja/core/M5NanoC6)
On the M5Stack NanoC6, the LED (Blue) is assigned to GPIO7. The sample project's Main.swift, on the other hand, specifies GPIO8 as the LED pin.
In other words, you just need to change the pin number to 7.
```swift:Main.swift
@_cdecl("app_main")
func main() {
  print("Hello from Swift on ESP32-C6!")

  var ledValue: Bool = false
  let blinkDelayMs: UInt32 = 500
  let led = Led(gpioPin: 8)

  while true {
    led.setLed(value: ledValue)
    ledValue.toggle()
    vTaskDelay(blinkDelayMs / (1000 / UInt32(configTICK_RATE_HZ)))
  }
}
```
Change it to the following.
```swift:Main.swift
@_cdecl("app_main")
func main() {
  print("Hello from Swift on ESP32-C6!")

  var ledValue: Bool = false
  let blinkDelayMs: UInt32 = 500
  let led = Led(gpioPin: 7) // The M5Stack NanoC6 built-in LED is on GPIO7 (the sample uses 8)

  while true {
    led.setLed(value: ledValue)
    ledValue.toggle()
    vTaskDelay(blinkDelayMs / (1000 / UInt32(configTICK_RATE_HZ)))
  }
}
```

Build and flash it again, and the LED should blink.
![M5Stack NanoC6 blinking (light off)](/images/m5stacknanoc6-blinking1.jpg "Blinking (light off)")
![M5Stack NanoC6 blinking (light on)](/images/m5stacknanoc6-blinking2.jpg "Blinking (light on)")

## Conclusion
This time, I fixed the pin number in the sample code and blinked the LED on an M5Stack NanoC6. Just as reading documentation matters in programming, I learned that checking spec sheets and pin maps is very important in embedded development.
I also found that although the ESP32-C6-BUG assumed by the sample is hard to get and fairly expensive at 4,785 yen, you can try Embedded Swift with the M5Stack NanoC6, which costs 1,276 yen. There are still few articles about actually running Embedded Swift, so I hope this helps anyone who wants to try it.

## References
- [Go small with Embedded Swift](https://developer.apple.com/videos/play/wwdc2024/10197/)
- [Byte-sized Swift: Building Tiny Games for the Playdate](https://www.swift.org/blog/byte-sized-swift-tiny-games-playdate/)
- [Get Started with Embedded Swift on ARM and RISC-V Microcontrollers](https://www.swift.org/blog/embedded-swift-examples/)
- [GitHub : apple/swift-embedded-examples](https://github.com/apple/swift-embedded-examples/tree/main)
- [Swift Matter Examples Tutorials](https://apple.github.io/swift-matter-examples/tutorials/swiftmatterexamples/setup-macos/)
- [NanoC6 - m5-docs - M5Stack](https://docs.m5stack.com/ja/core/M5NanoC6)
- [M5Stack NanoC6](https://www.switch-science.com/products/9570?srsltid=AfmBOorJRglcRJ3WqE-mQq-XjthkeevmB39LyzU5dFA58r3zqGl8vbjb)
- [diagram.json File Format](https://docs.wokwi.com/diagram-format)
- [idf_component.yml Manifest File — IDF Component Management documentation](https://docs.espressif.com/projects/idf-component-manager/en/latest/reference/manifest_file.html)
- [Dependencies.lock File — IDF Component Management documentation](https://docs.espressif.com/projects/idf-component-manager/en/latest/reference/dependencies_lock.html)
- [Build System (CMake) — ESP-IDF Programming Guide release-v3.3 documentation](https://docs.espressif.com/projects/esp-idf/en/release-v3.3/api-guides/build-system-cmake.html)
- [ESP32-C6-BUG Prokyber | Mouser Japan](https://www.mouser.jp/ProductDetail/Prokyber/ESP32-C6-BUG?qs=ZcfC38r4Pou1X3IbFvgUPQ%3D%3D&srsltid=AfmBOooiRK2CNlgGq1oGmTfcpbewYg8Pd-TurtD67HyhEXK8YB_cZg8-)
