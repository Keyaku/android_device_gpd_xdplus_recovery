# Patches against trees outside this repo

A fresh checkout of the TWRP base gets none of these automatically. Apply them after `repo sync`, or the build fails.

Verify a patch is still applied with a reverse check rather than by reading the source:

```bash
git -C <target-repo> apply --check --reverse <patch>
```

| Patch | Target repo | Why |
|---|---|---|
| `0001-bootable_recovery-tolerate-a-LUN-path-without-a-conversion.patch` | `bootable/recovery` (TeamWin, `android-11`) | Build fix, needed by any device whose mass-storage LUN path contains no `%d`. |
| `0002-theme-drop-navbar-settings-and-twrp-app.patch` | `bootable/recovery` (TeamWin, `android-11`) | Drops dead UI from the shared theme pages: navbar settings, and the TWRP app installer. |

## 0001 — LUN path without a conversion

TWRP calls `sprintf(lun_file, CUSTOM_LUN_FILE, 0)` in six places, guarded at *runtime* by a check for `%` in the path. On this device the path is `/sys/class/android_usb/android0/f_mass_storage/lun/file` — verified against the live device, which exposes a single `lun` directory and no `lun0`/`lun1` — so the format string has no conversion, the compiler sees an unused argument, and `-Wformat-extra-args` under `-Werror` fails the build.

The path is correct and the runtime guard already handles it; only the compile-time check needed satisfying. The patch routes `CUSTOM_LUN_FILE` through a function returning `const char*`, so the format string is no longer a literal the checker can fold. Behaviour is unchanged on devices whose path does contain `%d`.

⚠️ A `static const char* const` initialised from the macro is **not** enough — clang folds through it and the warning fires anyway. The indirection has to be opaque.

## 0002 — dead UI in the shared theme pages

Two removals from `gui/theme/common/landscape.xml`, which `TW_CUSTOM_THEME` cannot reach because it only replaces `ui.xml`:

- **Navbar settings** — the "Reversed navbar layout" checkbox and six navbar-alignment radio buttons. This device has physical buttons, so the on-screen navbar is removed by our theme and these settings control nothing.
- **"Install TWRP App"** — the Advanced menu entry that offers to install the official TWRP app. The theme is the only entry point (nothing in the C++ navigates to that page), so removing the entry removes the feature. The now-unreachable `installapp` page is deliberately left in place to keep the patch small.
