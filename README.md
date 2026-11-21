# F19Layer

A macOS 13+ login-session helper. Pressing Right Command or F18 posts a marked F18 down/up pair to the native previous-input-source shortcut. There is no timer or per-key process launch. Use two enabled input sources for predictable Korean/English toggling.

Right Shift is a dedicated keyboard layer, not a capitalization key. On the physical US-layout positions, [ sends Up, ; sends Left, ' sends Right, and / sends Down. Other keys pass through without Right Shift. Left Shift and other modifiers still work. Pointer events are outside the keyboard layer.

The menu bar shows `가` for Korean and `A` for English. It follows the selected macOS input source, including changes made outside F19Layer. Other or unidentified sources show `·`. Hover over the indicator for the source name. Click the indicator and choose **Layer config** to view or edit the physical US-layout key assigned to each Right Shift arrow in a separate window. The menu also lets you toggle Right Command switching or quit. Changes apply immediately and persist across launches. Unassign a key before moving it to another direction.

## Credits and license

F19Layer is based in part on [gksdud v2.1.0](https://github.com/codingnoye/gksdud/tree/v2.1.0) by CodingNoye. Its function-key pulse handling and macOS input-source shortcut activation were adapted from that project. The [upstream MIT license](https://github.com/codingnoye/gksdud/blob/v2.1.0/LICENSE) permits modification and redistribution with the copyright and permission notice intact. [NOTICE](NOTICE) contains the full upstream notice and is also included in the app bundle.

## Build and try

Run `swift test`, then `sh package.sh`. The result is `dist/F19Layer.app`. The packaging script uses `F19Layer Local Signing` if that certificate exists in Keychain; otherwise it signs ad hoc. Set `SIGN_IDENTITY` to select another certificate. Reuse the same identity and install path to avoid repeated Accessibility prompts. A locally trusted certificate is for your own Mac; it is not a substitute for Developer ID signing and notarization for distribution.

1. Disable gksdud switching and its login item, let it restore its settings, and quit it before trying this helper. If Home Manager enables gksdud, disable that configuration before your next activation. Do not run two helpers that manage the input-source shortcut.
2. No manual F-key binding is needed. After obtaining Accessibility access and creating its keyboard event tap, the helper saves the previous “Select the previous input source” shortcut and assigns F18 on launch. If another enabled system shortcut already uses unmodified F18, setup stops without overwriting it. Use Left Command for normal shortcuts.
3. Copy the app to `~/Applications/F19Layer.app`, grant that copy Accessibility access, and open it. Hold Right Command while typing and check that the first character uses the new source. Test a held arrow, release Right Shift before the arrow key, and check that an unmapped letter stays lowercase.
4. For login startup, choose Quit F19Layer from the menu bar first. Create the per-user LaunchAgent below. This step is optional and should be run only once the manual test passes.

```sh
mkdir -p "$HOME/Library/LaunchAgents"
p="$HOME/Library/LaunchAgents/local.f19layer.helper.plist"
# Start with a new plist. Do not replace an existing job.
( set -C; : > "$p" ) && {
  plutil -create xml1 "$p" &&
  plutil -insert Label -string local.f19layer.helper "$p" &&
  plutil -insert ProgramArguments -array "$p" &&
  plutil -insert ProgramArguments.0 -string "$HOME/Applications/F19Layer.app/Contents/MacOS/F19Layer" "$p" &&
  plutil -insert LimitLoadToSessionType -string Aqua "$p" &&
  plutil -insert RunAtLoad -bool true "$p" &&
  launchctl bootstrap "gui/$(id -u)" "$p"
}
```

To stop the job, run `launchctl bootout "gui/$(id -u)/local.f19layer.helper"`. Move its plist out of LaunchAgents to prevent login startup. The F18 assignment persists after quitting. Before uninstalling or enabling gksdud again, stop the helper, then run `~/Applications/F19Layer.app/Contents/MacOS/F19Layer --restore-shortcut` (adjust the path for your copy). This restores the saved binding only if the current one still matches F18; it preserves a later manual change.
