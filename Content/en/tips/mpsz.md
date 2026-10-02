---
title: "What is the MPSZ format for representing mahjong tiles?"
description: "How to write a mahjong hand (a sequence of tiles) using only digits and four letters in the MPSZ format."
keywords: ["Mahjong", "mpsz", "Riichi"]
---

# MPSZ format for representing mahjong tiles

The MPSZ format is a notation for writing down mahjong tiles, such as a hand, using only digits and the four letters m, p, s and z. Because it can be typed on any keyboard and needs no special fonts or images, it is widely used on social media, in blogs and as input for mahjong tools.

For example, the following hand is written as `123m456p789s11z` in MPSZ format.

<p class="mahjongTiles">🀇🀈🀉🀜🀝🀞🀖🀗🀘🀀🀀</p>

## Basic rules

### A tile is a digit followed by a suit letter

Each tile is written as a digit followed by a letter that indicates its suit.

| Letter | Suit | Digits | Example |
| ---- | ---- | ---- | ---- |
| m | Characters (Manzu) | 1–9 | `1m` = <span class="tile">🀇</span> |
| p | Dots (Pinzu) | 1–9 | `1p` = <span class="tile">🀙</span> |
| s | Bamboo (Souzu) | 1–9 | `1s` = <span class="tile">🀐</span> |
| z | Honors (Jihai) | 1–7 | `1z` = <span class="tile">🀀</span> (East) |

For honors, `1z` to `7z` stand for East, South, West, North, White, Green and Red, in that order.

### Consecutive tiles of the same suit share one letter

When several tiles of the same suit come in a row, write only their digits and put the letter once at the end.

- `1m2m3m` → `123m`
- `1m2m3m4p4p` → `123m44p`

Each digit belongs to the suit of the next letter that follows it, so `123m44p` means "1, 2 and 3 of characters, and 4 and 4 of dots".

### Red fives are written as 0

A red five (aka dora) is written with `0` instead of `5`.

- `0m` = <span class="tile" style="color:red">🀋</span> (red five of characters)
- `0p` = <span class="tile" style="color:red">🀝</span> (red five of dots)
- `0s` = <span class="tile" style="color:red">🀔</span> (red five of bamboo)

## Extended notation

The following notation is available in some tools, such as [Mahjong Tile Converter](/en/product/mahjongtileconverter). Note that not every tool supports it.

| Notation | Meaning | Example |
| ---- | ---- | ---- |
| `r` + tile | Red tile (same as `0`) | `r5m` = <span class="tile" style="color:red">🀋</span> |
| `-` | Back of a tile | `-` = <span class="tile">🀫</span> |

## List of tiles

<div class="mahjongTable">

| Letter | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 (red) |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| m | 🀇 | 🀈 | 🀉 | 🀊 | 🀋 | 🀌 | 🀍 | 🀎 | 🀏 | <span style="color:red">🀋</span> |
| p | 🀙 | 🀚 | 🀛 | 🀜 | 🀝 | 🀞 | 🀟 | 🀠 | 🀡 | <span style="color:red">🀝</span> |
| s | 🀐 | 🀑 | 🀒 | 🀓 | 🀔 | 🀕 | 🀖 | 🀗 | 🀘 | <span style="color:red">🀔</span> |
| z | 🀀<small>East</small> | 🀁<small>South</small> | 🀂<small>West</small> | 🀃<small>North</small> | 🀆<small>White</small> | 🀅<small>Green</small> | 🀄︎<small>Red</small> | | | |

</div>

## Tools for converting MPSZ format into tiles

### [Mahjong Tile Converter](/en/product/mahjongtileconverter)

A macOS menu bar app that converts a hand written in MPSZ format into Unicode mahjong tile characters. Since the result is plain text, you can copy and paste it straight into social media or notes. You can also check your conversion history and convert from notations other than MPSZ.

### [[Mahjong] Creating a program to restore MPSZ format tile symbols to tile form using Javascript (Japanese)](https://mahjong.org/program_018/)

An article that introduces a web application for displaying graphical tiles from MPSZ format, and explains how it was built.
