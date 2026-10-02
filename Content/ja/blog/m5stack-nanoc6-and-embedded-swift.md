---
title: Embedded SwiftでM5Stack NanoC6を動かす
description: Embedded Swiftのサンプルプロジェクトesp32-led-blink-sdkを使い、M5Stack NanoC6のLEDを点滅させる。
keywords: ["Swift", "ESP32-C6", "Embedded Swift"]
genre: Embedded Swift
date: 2025/1/14
---
# Embedded SwiftでM5Stack NanoC6を動かす
この記事では、Embedded Swiftのサンプルプロジェクトesp32-led-blink-sdkを使い、M5Stack NanoC6のLEDを点滅させる。
![M5Stack NanoC6](/images/m5stacknanoc6.png "M5Stack NanoC6")
出典 : [NanoC6 - m5-docs - M5Stack](https://docs.m5stack.com/ja/core/M5NanoC6)
## はじめに
WWDC2024でEmbedded Swiftが紹介され、Appleデバイスだけでなく組み込み機器もSwiftで開発できるようになりつつある。ただし執筆時点では正式リリースされておらず、SwiftのDEVELOPMENT SNAPSHOTをインストールして使う必要がある。
そこで、普段のAppleデバイス向けの開発から一歩踏み出し、組み込み機器の開発に挑戦してみることにした。今回の目標は、**M5Stack NanoC6のLEDを点滅させること**だ。組み込み開発は初めてなので誤りがあるかもしれないが、温かく見守っていただけると幸いだ。

## Embedded Swiftとは
Embedded Swiftは、Swiftで組み込み機器向けのプログラムを書くための仕組みだ。通常のSwiftとは異なり、Embedded Swift専用のコンパイルモードでビルドする。そのため、使えるライブラリなどの依存関係は大きく異なるが、Swiftの構文の大部分はそのまま利用できる。裏を返せば、一部には使えない構文もある。
大きく注目を集めたのはWWDC 2024のセッション[「Embedded Swiftでサイズを縮小」](https://developer.apple.com/jp/videos/play/wwdc2024/10197/)だが、それより前にSwift.orgのブログ記事[「Byte-sized Swift: Building Tiny Games for the Playdate」](https://www.swift.org/blog/byte-sized-swift-tiny-games-playdate/)や[「Get Started with Embedded Swift on ARM and RISC-V Microcontrollers」](https://www.swift.org/blog/embedded-swift-examples/)で紹介されていた。
後者の記事のタイトルからわかる通り、Embedded Swiftはどの組み込み機器でも使えるわけではなく、対象はARMアーキテクチャとRISC-Vアーキテクチャのマイクロコントローラだ。Embedded Swiftで開発したい場合は、対応した機器を用意する必要がある。

## 組み込み機器の選び方
### マイクロコントローラで選ぶ
Embedded Swiftに対応しているかどうかは、機器に搭載されているマイクロコントローラ（CPUを含むチップ）で決まる。そのため、機器を選ぶときはマイクロコントローラを確認すればよい。ほかにも使えるマイクロコントローラはあると思うが、ここではサンプルプロジェクトで動作が確認されているものだけを挙げる。
- ARM
  - STM32F746
  - RP2040（サンプルでは、これを搭載したRaspberry Pi Picoとして紹介されている）
  - nRF52840
- RISC-V
  - ESP32-C6

この中から選べば安全だろう。環境構築やCライブラリなど組み込みの知識があれば、これ以外のマイクロコントローラでも動かせるかもしれないが、今の私にはわからない。
### M5Stack NanoC6を選んだ
今回は、ESP32-C6を搭載したM5Stack NanoC6を使う。以降の内容はESP32-C6を前提としているため、ほかのマイクロコントローラではそのまま当てはまらない点に注意してほしい。
## 環境構築
次に環境を構築する。基本的には、[Swift Matter Examples Tutorials](https://apple.github.io/swift-matter-examples/tutorials/swiftmatterexamples/setup-macos/)のmacOS向けの手順どおりに進める。

まず、XcodeとSwiftの最新のDEVELOPMENT SNAPSHOTをインストールする。

次に、ターミナルでSNAPSHOTがインストールされていることを確認し、SNAPSHOTのCFBundleIdentifierの値を調べておく。この値は、あとで環境変数TOOLCHAINSに指定する。以下の出力は一例だが、おおむね同じようになるはずだ。
最後の`swift --version`の出力にある`Target`が、使っているMacのアーキテクチャ（Apple シリコンならarm64）と一致しているかも確認しておくとよい。
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
Homebrewのインストール方法は省略する。Homebrewで、cmake・ninja・dfu-utilをインストールする。
```zsh
$ brew install cmake ninja dfu-util
```
次に、ホームディレクトリにespフォルダを作成し、その中にesp-idfとesp-matterをクローンしてインストールする。
その後、環境変数TOOLCHAINSに先ほど確認したCFBundleIdentifierの値を設定し、最後にそれぞれのexport.shを実行する。
なお、ここではチュートリアルに従ってesp-matterもインストールしているが、今回のサンプルプロジェクトでは使われていないようなので、不要かもしれない（検証はしていない）。
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

続いて、サンプルプロジェクトが含まれている[swift-embedded-examples](https://github.com/apple/swift-embedded-examples)をクローンし、そのフォルダでPythonの仮想環境を作って必要なパッケージをインストールする。`<path to swift-embedded-examples>`には、クローンしたswift-embedded-examplesのパスを入れる。
```zsh
$ git clone https://github.com/apple/swift-embedded-examples.git
$ cd <path to swift-embedded-examples>
$ python3 -m venv .venv
$ source .venv/bin/activate
$ python3 -m pip install -r Tools/requirements.txt
```
これで環境構築は完了だ。

## サンプルプロジェクトのファイル構成を確認
動かす前に、Swiftのプロジェクトがどのように構成されているのかを確かめておく。esp32-led-blink-sdkのファイルを一つずつ見ていく。
- main
  - BridgingHeader.h
  C言語のヘッダーファイル。ここでインポートしたものがSwiftから使える。
  - CMakeLists.txt
  main内のビルド設定を定義している。Swiftを使えるようにしているのもこのファイルだ。
  - idf_component.yml
  ESP-IDFのコンポーネントの依存関係を定義するファイル。今回は何も記載されていない。
  - Led.swift
  LED構造体を定義している。注目してほしいのは、ここで呼んでいる関数の定義がSwift側にない点だ。これらはC言語のライブラリで定義されており、BridgingHeader.hを通じて使えるようになっている。
  - Main.swift
  エントリーポイントとなるファイル。
- CMakeLists.txt
  `include($ENV{IDF_PATH}/tools/cmake/project.cmake)`が特徴的だ。ESP-IDFを利用するためにコンポーネントを登録するものらしいが、今のところはおまじないとして扱っている。
- dependencies.lock
  解決済みの依存関係を記録するファイル。ここでesp32c6を対象とすることが記録されているため、idf_component.ymlには記載しなくてよいのだと思われる。
- diagram.json
  基板のシミュレータであるWokwiで、基板の種類や配線を定義するJSONファイル。Visual Studio CodeにWokwi拡張機能をインストールすると、基板を画面上で確認できる。このプロジェクトでは、[ESP32-C6-BUG](https://www.mouser.jp/ProductDetail/Prokyber/ESP32-C6-BUG?qs=ZcfC38r4Pou1X3IbFvgUPQ%3D%3D&srsltid=AfmBOooiRK2CNlgGq1oGmTfcpbewYg8Pd-TurtD67HyhEXK8YB_cZg8-)の基板が表示される。今回はシミュレーションを使わないので触れない。
- sdkconfig
  ESP-IDFの設定ファイル。ファイル内のコメントによると、自動生成されたもののようだ。
- sdkconfig.old
  sdkconfigの以前の版。こちらも自動生成されたもののようだ。
- wokwi.toml
  Wokwiの設定ファイル。
  

### ファイル構成からわかること
このプロジェクトの特徴は、Swift Package Managerを使わず、ESP-IDFのCMakeでビルドしている点だ。一方、同じくEmbedded Swiftを使う[swift-playdate-examples](https://github.com/apple/swift-playdate-examples)ではSwift Package Managerを使っている。ESP32-C6でもSwift Package Managerを使ったプロジェクト構成にできるかどうかは、今後検証してみたい。

## サンプルプロジェクトを動作させてみる
いよいよ、サンプルプロジェクトを動かしてLEDを点滅させる。M5Stack NanoC6はESP32-C6を搭載しているので、ESP32-C6向けのesp32-led-blink-sdkを使う。
基板をMacに接続し、以下のコマンドを実行する。
```zsh
$ cd esp32-led-blink-sdk
$ export TOOLCHAINS=org.swift.59202406031a
$ . <path-to-esp-idf>/export.sh
$ idf.py set-target esp32c6
$ idf.py build
$ idf.py flash
```
### そのままではLEDが点滅しない
ビルドと書き込みは成功するが、LEDは点滅しないはずだ。これは、サンプルプロジェクトが別の基板である[ESP32-C6-BUG](https://www.mouser.jp/ProductDetail/Prokyber/ESP32-C6-BUG?qs=ZcfC38r4Pou1X3IbFvgUPQ%3D%3D&srsltid=AfmBOooiRK2CNlgGq1oGmTfcpbewYg8Pd-TurtD67HyhEXK8YB_cZg8-)向けに書かれているためだ。
[M5Stack NanoC6のドキュメント](https://docs.m5stack.com/ja/core/M5NanoC6)を確認してみよう。注目してほしいのは、ピンマップの記載だ。
![M5Stack NanoC6 ピンマップ](/images/m5stacknanoc6-pinmap.png "ピンマップ")
出典 : [NanoC6 - m5-docs - M5Stack](https://docs.m5stack.com/ja/core/M5NanoC6)
M5Stack NanoC6では、LED(Blue)はGPIO7に割り当てられている。一方、サンプルプロジェクトのMain.swiftでは、LEDのピンとしてGPIO8が指定されている。
つまり、ピン番号を7に変更すればよい。
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
を
```swift:Main.swift
@_cdecl("app_main")
func main() {
  print("Hello from Swift on ESP32-C6!")

  var ledValue: Bool = false
  let blinkDelayMs: UInt32 = 500
  let led = Led(gpioPin: 7) // M5NanoC6内蔵のLEDはGPIO7だったのでこの値に変更(デフォルトは8)

  while true {
    led.setLed(value: ledValue)
    ledValue.toggle()
    vTaskDelay(blinkDelayMs / (1000 / UInt32(configTICK_RATE_HZ)))
  }
}
```
に変更する。

もう一度ビルドして書き込むと、LEDが点滅するはずだ。
![M5Stack NanoC6の点滅(消灯時)](/images/m5stacknanoc6-blinking1.jpg "点滅(消灯時)")
![M5Stack NanoC6の点滅(点灯時)](/images/m5stacknanoc6-blinking2.jpg "点滅(点灯時)")

## 最後に
今回は、サンプルコードのピン番号を修正し、M5Stack NanoC6でLEDを点滅させた。プログラミングでドキュメントを読むことが大切なのと同じく、組み込み開発ではスペックシートやピンマップを確認することがとても重要だと学んだ。
また、サンプルが想定しているESP32-C6-BUGは入手しにくく、価格も4,785円と高めだが、1,276円のM5Stack NanoC6でもEmbedded Swiftを試せることがわかった。Embedded Swiftを実際に動かしてみた日本語の記事はまだ多くないので、これから試す人の役に立てば幸いだ。

## 参考資料
- [Embedded Swiftでサイズを縮小](https://developer.apple.com/jp/videos/play/wwdc2024/10197/)
- [Byte-sized Swift: Building Tiny Games for the Playdate](https://www.swift.org/blog/byte-sized-swift-tiny-games-playdate/)
- [Get Started with Embedded Swift on ARM and RISC-V Microcontrollers](https://www.swift.org/blog/embedded-swift-examples/)
- [GitHub : apple/swift-embedded-examples](https://github.com/apple/swift-embedded-examples/tree/main)
- [Swift Matter Examples Tutorials : Swift Matter Examples Tutorials](https://apple.github.io/swift-matter-examples/tutorials/swiftmatterexamples/setup-macos/)
- [NanoC6 - m5-docs - M5Stack](https://docs.m5stack.com/ja/core/M5NanoC6)
- [M5Stack NanoC6](https://www.switch-science.com/products/9570?srsltid=AfmBOorJRglcRJ3WqE-mQq-XjthkeevmB39LyzU5dFA58r3zqGl8vbjb)
- [diagram.json File Format](https://docs.wokwi.com/diagram-format)
- [idf_component.yml Manifest File — IDF Component Management  documentation](https://docs.espressif.com/projects/idf-component-manager/en/latest/reference/manifest_file.html)
- [Dependencies.lock File — IDF Component Management  documentation](https://docs.espressif.com/projects/idf-component-manager/en/latest/reference/dependencies_lock.html)
- [Build System (CMake) -  -  — ESP-IDF Programming Guide release-v3.3 documentation](https://docs.espressif.com/projects/esp-idf/en/release-v3.3/api-guides/build-system-cmake.html)
- [ESP32-C6-BUG Prokyber | Mouser 日本](https://www.mouser.jp/ProductDetail/Prokyber/ESP32-C6-BUG?qs=ZcfC38r4Pou1X3IbFvgUPQ%3D%3D&srsltid=AfmBOooiRK2CNlgGq1oGmTfcpbewYg8Pd-TurtD67HyhEXK8YB_cZg8-)