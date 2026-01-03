# Change Log

## v4.2.0 (2019-06-15)

**Implemented enhancements:**

- Updated to include all missing emojis

## [v4.0.0](https://github.com/bonusly/gemojione/tree/v3.3.0) (2019-02-08)

**Implemented enhancements:**

- Upgraded to EmojiOne version 4.5


## [v3.3.0](https://github.com/bonusly/gemojione/tree/v3.3.0) (2017-07-14)

[Full Changelog](https://github.com/bonusly/gemojione/compare/v3.2.0...v3.3.0)

**Implemented enhancements:**

- Add aliases search support in `replace_named_moji_with_images`.
- Add emoji finder by shortname.
- Add access to emoji list.
- Add emoji finder by category.

**Fixed bugs:**

- Remove trailing comma from `cartwheel_tone4`.

**Merged pull requests:**

- Add aliases search support in replace_named_moji_with_images [\#38](https://github.com/bonusly/gemojione/pull/38) ([bonusly](https://github.com/bonusly))

- Enable emoji retrieval by shortname [\#42](https://github.com/bonusly/gemojione/pull/42) ([amyspark](https://github.com/amyspark))

- Remove misplaced comma [\#49](https://github.com/bonusly/gemojione/pull/49) ([connorshea](https://github.com/connorshea))

- Enable emoji access to emoji list [\#43](https://github.com/bonusly/gemojione/pull/43) ([ryosuke-endo](https://github.com/ryosuke-endo))

- emoji group find by category [\#44](https://github.com/bonusly/gemojione/pull/44) ([ryosuke-endo](https://github.com/ryosuke-endo))

- Be clearer about spritesheet sizing [\#47](https://github.com/bonusly/gemojione/pull/47) ([gnclmorais](https://github.com/gnclmorais))

## [v3.2.0](https://github.com/bonusly/gemojione/tree/v3.2.0) (2016-08-22)

[Full Changelog](https://github.com/bonusly/gemojione/compare/v3.1.0...v3.2.0)

**Implemented enhancements:**

- Sprite and  ASCII!  [\#25](https://github.com/bonusly/gemojione/pull/25) ([naveed-ahmad](https://github.com/naveed-ahmad))

## [v3.1.0](https://github.com/bonusly/gemojione/tree/v3.1.0) (2016-07-30)

[Full Changelog](https://github.com/bonusly/gemojione/compare/v3.0.1...v3.1.0)

**Implemented enhancements:**

- Add helper for named mojis as well [\#27](https://github.com/bonusly/gemojione/pull/27) ([gnclmorais](https://github.com/gnclmorais))
- Add find by keyword method [\#24](https://github.com/bonusly/gemojione/pull/24) ([bonusly](https://github.com/bonusly))
- Add gay\_pride\_flag [\#22](https://github.com/bonusly/gemojione/pull/22) ([bonusly](https://github.com/bonusly))
- Update mrs\_claus asset for glasses reflexion  [\#28](https://github.com/bonusly/gemojione/issues/28)

**Fixed bugs:**

- Bring back `speech_left` definition that was wrongly removed.
- Remove duplicate ascii alias for `innocent` definition.


## [v3.0.1](https://github.com/bonusly/gemojione/tree/v3.0.1) (2016-07-16)
[Full Changelog](https://github.com/bonusly/gemojione/compare/v3.0.0...v3.0.1)

**Fixed bugs:**

* Changed shopping cart category (from `travel` to `objects`)

**Implemented enhancements:**

* Add `facepalm` alias to `face_palm` definitions.

## [v3.0.0](https://github.com/bonusly/gemojione/tree/v3.0.0) (2016-07-12)
[Full Changelog](https://github.com/bonusly/gemojione/compare/v2.6.1...v3.0.0)

**Implemented enhancements:**

- Add Unicode 9 Emoji [\#10](https://github.com/bonusly/gemojione/issues/10)
- Add SVG usage option [\#19](https://github.com/bonusly/gemojione/pull/19) ([bonusly](https://github.com/bonusly))

**Fixed bugs:**

- Remove duplicate definitions for the same uncode [\#13](https://github.com/bonusly/gemojione/issues/13)
- Categories for some emoji are incorrect [\#11](https://github.com/bonusly/gemojione/issues/11)

**Merged pull requests:**

- Unicode9 [\#18](https://github.com/bonusly/gemojione/pull/18) ([bonusly](https://github.com/bonusly))
- Rails check updated [\#15](https://github.com/bonusly/gemojione/pull/15) ([kendrikat](https://github.com/kendrikat))
- Remove duplicate defs same unicode [\#14](https://github.com/bonusly/gemojione/pull/14) ([bonusly](https://github.com/bonusly))
- Change categories according to EmojiOne [\#12](https://github.com/bonusly/gemojione/pull/12) ([bonusly](https://github.com/bonusly))

**Breaking changes:**

- `egg` renamed to `cooking`. (Unicode9 includes true `egg` definition).
- Dropped support for ruby v1.x because json dependency no longer supports it.
- Standarized recategorization. (`celebration`, `emoticons`, `objects_symbols`, `other`, `places`, `travel_places` categories removed). New standarized categories are the following:

```js
{
  "activity": 145,
  "flags": 257,
  "food": 85,
  "modifier": 5,
  "nature": 161,
  "objects": 178,
  "people": 570,
  "symbols": 272,
  "travel": 119
}
```

- `foods` category has benn renamed to `food`.
- People serving assets directly from the gem must change:

```ruby
config.assets.paths << Gemojione.index.images_path

# to

config.assets.paths << Gemojione.images_path
```

- If using new SVG option (`Gemojione.use_svg = true`), asset precompilation config should also be changed:

```ruby
config.assets.precompile << "emoji/*.png"

# to

config.assets.precompile << "emoji/*.svg"
```

- The `install_assets` rake task now installs both asset types (PNGs and SVGs).

- The following definitions have been removed because they are not actually emoji:

```
airplane_northeast
airplane_small_up
anger_left
ascending_notes
ballot_box_check
ballot_box_x
ballot_x
book2
bouquet2
boys_symbol
bullhorn
bullhorn_waves
calculator
cancellation_x
cartridge
celtic_cross
clockwise_arrows
computer_old
cross_heavy
cross_white
crossbones
descending_notes
desktop_window
document
document_text
envelope_back
envelope_flying
envelope_stamped
envelope_stamped_pen
finger_pointing_down
finger_pointing_down2
finger_pointing_left
finger_pointing_right
finger_pointing_up
fire_engine_oncoming
flip_phone
floppy_black
floppy_white
folder
folder_open
frame_tiles
frame_x
girls_symbol
hand_splayed_reverse
hand_victory
hard_disk
heart_tip
info
jet_up
keyboard_mouse
keyboard_with_jacks
keycap_ten
left_receiver
left_writing_hand
light_check_mark
lips2
mood_bubble
mood_bubble_lightning
mood_lightning
mouse_one
network
note
note_empty
notepad
notepad_empty
optical_disk
page
pages
pencil3
pennant_black
pennant_white
piracy
prohibited
pushpin_black
right_speaker
right_speaker_one
right_speaker_three
ringing_bell
rosette_black
speech_left
speech_right
speech_three
speech_two
stereo
stock_chart
telephone_black
telephone_white
thought_left
thought_right
thumbs_down_reverse
thumbs_up_reverse
train_diesel
triangle_round
turned_ok_hand
wired_keyboard
```

## [v2.6.1](https://github.com/bonusly/gemojione/tree/v2.6.1) (2016-06-24)
[Full Changelog](https://github.com/bonusly/gemojione/compare/v2.6.0...v2.6.1)

**Implemented enhancements:**

- Merge keywords from emojione gem.
- Add a couple definitions that where mixed with old ones.

**Fixed bugs:**

- Clean duplicate keywords.
- Make all `unicode-alternates` an array, uppercase value.



## [v2.6.0](https://github.com/bonusly/gemojione/tree/v2.6.0) (2016-06-17)
[Full Changelog](https://github.com/bonusly/gemojione/compare/v2.5.0...v2.6.0)

**Fixed bugs:**

- Some mojis break regex [\#9](https://github.com/bonusly/gemojione/issues/9)

**Closed issues:**

- Add moji property for all / most of the definitions [\#8](https://github.com/bonusly/gemojione/issues/8)

**Merged pull requests:**

- Add a \(nonobstructive\) setting for image size [\#7](https://github.com/bonusly/gemojione/pull/7) ([kendrikat](https://github.com/kendrikat))

## [v2.5.0](https://github.com/bonusly/gemojione/tree/v2.5.0) (2016-06-14)
[Full Changelog](https://github.com/bonusly/gemojione/compare/v2.4.0...v2.5.0)

**Merged pull requests:**

- Add Gemojione.replace\_named\_moji\_with\_images\(string\) [\#6](https://github.com/bonusly/gemojione/pull/6) ([kendrikat](https://github.com/kendrikat))

## [v2.4.0](https://github.com/bonusly/gemojione/tree/v2.4.0) (2016-06-02)
[Full Changelog](https://github.com/bonusly/gemojione/compare/v2.3.0...v2.4.0)

**Implemented enhancements:**

- Updated emoji images to match EmojiOne Spring update.



## [v2.3.0](https://github.com/bonusly/gemojione/tree/v2.3.0) (2016-05-15)
[Full Changelog](https://github.com/bonusly/gemojione/compare/v2.2.1...v2.3.0)

**Merged pull requests:**

- test against recent rubies [\#4](https://github.com/bonusly/gemojione/pull/4) ([ZJvandeWeg](https://github.com/ZJvandeWeg))
- Ablility to get an emoji by ascii [\#3](https://github.com/bonusly/gemojione/pull/3) ([ZJvandeWeg](https://github.com/ZJvandeWeg))

## [v2.2.1](https://github.com/bonusly/gemojione/tree/v2.2.1) (2016-02-11)
[Full Changelog](https://github.com/bonusly/gemojione/compare/v2.2.0...v2.2.1)

**Merged pull requests:**

- Add Index\#images\_path method [\#2](https://github.com/bonusly/gemojione/pull/2) ([tsigo](https://github.com/tsigo))

## [v2.2.0](https://github.com/bonusly/gemojione/tree/v2.2.0) (2016-02-11)
[Full Changelog](https://github.com/bonusly/gemojione/compare/v2.1.1...v2.2.0)

**Implemented enhancements:**

- New 2016 emoji design and several new emoji.

## [v2.1.1](https://github.com/bonusly/gemojione/tree/v2.1.1) (2015-12-08)
[Full Changelog](https://github.com/bonusly/gemojione/compare/v2.1.0...v2.1.1)

**Merged pull requests:**

- Remove executable bit from images [\#1](https://github.com/bonusly/gemojione/pull/1) ([balasankarc](https://github.com/balasankarc))

## [v2.1.0](https://github.com/bonusly/gemojione/tree/v2.1.0) (2015-10-09)
[Full Changelog](https://github.com/bonusly/gemojione/compare/v2.0.1...v2.1.0)

**Implemented enhancements:**

- Add new emoji images.

## [v2.0.1](https://github.com/bonusly/gemojione/tree/v2.0.1) (2015-03-18)
[Full Changelog](https://github.com/bonusly/gemojione/compare/v2.0.0...v2.0.1)

**Implemented enhancements:**

- Add memo alias for :pencil:.

## [v2.0.0](https://github.com/bonusly/gemojione/tree/v2.0.0) (2015-03-05)
[Full Changelog](https://github.com/bonusly/gemojione/compare/v1.0.1...v2.0.0)

**Initial gem release**

- Using [emoji gem](https://github.com/wpeterson/emoji) as base, fork was extracted and took it's own path.

\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
