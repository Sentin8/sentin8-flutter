# sentin8-flutter - Platform Flutter Package

## 1. Summary

The **single** Sentin8 Flutter package: all shared Flutter
infrastructure (native + web) lives here - the sentin8 theme and
design system, the shell/bootstrap widgets, and `Bff8ApiClient`
(the only approved backend path for every app; apps never call
backend services directly, architecture-principles §Flutter).

## 2. Motivation

- **One package, no copy-paste.** Theme, boot, and the BFF client are
  implemented once; apps import what they need.
- **Native-only features** are guarded by conditional imports - the
  web build never links native-only code.
- **Design system compliance by construction**: 4px grid, glass
  panels, Royal Gold `#D4AF37` accent, Inter font, WCAG AA minimum;
  tenant branding overrides load from `sentin8_sys_branding`.

## 3. Layout

```
sentin8-flutter/
└── lib/          # theme · shell · Bff8ApiClient · shared widgets
```

## 4. Usage

Depend on it via the pubspec path/git pin from each app repo and
import the modules you need:

```yaml
dependencies:
  sentin8_flutter:
    git:
      url: https://github.com/Sentin8/sentin8-flutter
```

All backend traffic routes through `Bff8ApiClient →
Sentin8:BFF /proxy/{service}/…` - the standalone direct-HTTP pattern
is deprecated (design `sentin8-flutter-component-library.md`).

---

**Architecture & Design:** sentin8:flutter and its underlying concepts were designed by [Hamid Jahanzad](https://www.linkedin.com/in/hamidjahanzad/).
