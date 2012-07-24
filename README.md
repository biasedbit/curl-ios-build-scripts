Curl iOS build scripts
======================

Automated scripts to build curl for iOS. Supports:

- iPhoneSimulator (i386)
- newer iPhones/iPads (arm v7)

> **NOTE**  
> These scripts **no longer compile for armv6**

---

## Default configuration

The scripts are configured to produce the smallest binary possible, with Curl being configured only to support the HTTP protocol (no FTP, DICT, FILE, etc).

All builds scripts share this configuration, although you can chose to include/exclude HTTPS support.

---

## Building without HTTPS support

The smallest possible binary you can achieve is by compiling curl without HTTPS support (which removes the dependency on external libs).

You can find the build scripts for curl without HTTPS support on `without-https/` folder.

- **Dependencies:** none
- **Total binary size:** ~900KB (~900KB for libcurl.a)

---

## Building with HTTPS support via native iOS/OSX SSL (darwin ssl)

> **NOTE**  
> This is only present in curl 7.27's nightly builds, so it's still unstable. Use at your risk.

If you want the generated curl binary to have HTTPS support via native iOS/OSX SSL implementation (darwin ssl), use the build scripts at `with-https-darwinssl/` folder.

**This is the recommended SSL implementation**

- **Dependencies:** none
- **Total binary size:** ~900KB (~900KB for libcurl.a)

---

## Building with HTTPS support via OpenSSL

If you want the generated curl binary to have HTTPS support via OpenSSL (Apache-style license), use the build scripts at `with-https-openssl/` folder.

- **Dependencies:** libssl
- **Total binary size:** ~2.1MB (~900KB for libcurl.a, ~1.2MB for libssl.a)

---

## Using on your project

After you've compiled the project, all you need to do is include one of the generated `*.a` files (the universal, i386 or armv7) on your project and all the headers. The `*.a` files can be found on `lib/` folder and the header files under `include/`.

When you add the files to the Xcode project, Xcode will automatically add the library files to the link build stage, i.e. you just need to add the `*.a` and `*.h` files to your project and it'll all work.

These scripts build CURL with libz support so you'll need to add `libz.dylib` to your projects.
If you're using the native SSL implementation, you'll need the `Security.framework` as well.

> **NOTE**  
> The directories above are relative to the directory of the build branch you chose: `without-https`, `with-https-openssl` or `with-https-gnutls`

---

## Optimizing for space on your apps

The scripts generate 3 kinds of binaries:

1. One with all the architectures combined (i386 and armv7);
2. One with just i386, to use on OSX development;
3. One with just armv7, to use on phones;

For development on iOS, the first one is recommended - allows you to run the app on both the simulator and the physical devices.

When you're about to build the final release (to submit to the app store), you should use the third one, as it is slightly smaller in size.

> **ProTip™**  
> Use different build targets, and include different variations of the above files in each of them so this process is automatic.

---

## Acknowledgments

These scripts are based on the excellent work of [Felix Schulze (x2on)](https://github.com/x2on), with some help from [Bob](http://stackoverflow.com/questions/9039554/using-libcurl-on-ios-5-as-an-alternative-to-nsurlconnection/9528936#9528936).

Also huge thanks to [Jonas Schnelli](https://github.com/jonasschnelli) for the pull request that included native Darwin SSL support.