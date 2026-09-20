# 3x-ui for rootless iOS 16

This directory contains the reproducible part of the 3x-ui port tested on a
rootless jailbroken iPhone running iOS 16.6. It keeps the upstream web panel and
Xray configuration model, but replaces the Linux service layer with launchd and
uses `/var/jb` throughout.

The port is intentionally pinned to upstream `v2.3.8` and Xray-core `v1.8.16`,
which are the versions used by the tested installation. Runtime databases,
generated Xray configuration, certificates, logs, credentials, and compiled
binaries are not stored in Git.

## Components

- `build.sh` cross-compiles the upstream panel and Xray-core for `ios/arm64` and
  builds the small Jetsam-aware launcher.
- `launcher.c` raises the process Jetsam task limit to 256 MiB before replacing
  itself with either `x-ui.real` or `xray-ios-arm64.real`.
- `package.sh` creates an `iphoneos-arm64` rootless Debian package suitable for
  Sileo or `dpkg`.
- `layout/` contains the launchd definition, shell environment, and package
  maintainer scripts.
- The repository-root `x-ui.sh` is the upstream v2.3.8 management CLI adapted
  to launchd. Linux-only operations are retained in the menu but disabled.

## Build host requirements

Build on macOS with Xcode, Go 1.22.4, `curl`, and `dpkg-deb` installed. The build
scripts use the iPhoneOS SDK and therefore cannot produce the final binaries on
Linux or Windows.

```sh
cd ios
./fetch-assets.sh
./build.sh
./package.sh
```

The package is written to `ios/build/com.xboxpig.3x-ui_2.3.8-ios1_iphoneos-arm64.deb`.
Set `IOS_MIN_VERSION` or `PACKAGE_REVISION` in the environment to override the
defaults.

## Install

Copy the package to the jailbroken device and install it as root:

```sh
dpkg -i com.xboxpig.3x-ui_2.3.8-ios1_iphoneos-arm64.deb
x-ui status
```

The package installs:

- panel: `/var/jb/usr/local/x-ui/x-ui.real`
- Xray: `/var/jb/usr/local/x-ui/bin/xray-ios-arm64.real`
- launchers: `/var/jb/usr/local/x-ui/x-ui` and
  `/var/jb/usr/local/x-ui/bin/xray-ios-arm64`
- database: `/var/jb/etc/x-ui/x-ui.db`
- logs: `/var/jb/var/log/x-ui`
- CLI: `/var/jb/usr/bin/x-ui`
- launchd label: `com.xboxpig.3x-ui` in the `user/501` domain

No default route, VPN profile, DNS setting, inbound, outbound, account, or TLS
certificate is created by the package. Configure those from the web panel after
installation.

## Management

Start a new root zsh login session and run `x-ui` for the upstream management
menu. Common non-interactive commands are:

```sh
x-ui status
x-ui start
x-ui stop
x-ui restart
x-ui settings
x-ui log
```

The package signs its Mach-O files with `ldid` during installation. It preserves
`/var/jb/etc/x-ui` during ordinary upgrades and removals; only `dpkg --purge`
removes the database and logs.

## Known scope

- Tested target: arm64, rootless jailbreak, iOS 16.6.
- The service uses the mobile launchd domain (`user/501`) because this is the
  arrangement validated to survive screen lock on the test device.
- Linux-only integrations such as systemd, firewalld, BBR, WARP, Fail2ban, and
  the upstream self-updater are not available in this port.
- Upgrading to a newer upstream 3x-ui release should be done as a separate
  rebase and device-validation pass rather than merging `main` blindly.
