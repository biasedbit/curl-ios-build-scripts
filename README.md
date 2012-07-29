Curl iOS build script
=====================

Script to build curl for iOS. Supports:

- iPhoneSimulator (i386)
- newer iPhones/iPads (arm v7)

Curl version `7.27.0` and above now supports native (Dawrwin) SSL so the other alternatives (GnuTLS and OpenSSL) have been removed. The script now compiles `libcurl.a` with SSL support at no additional binary size (yay!).

> **NOTES**  
> 1. These scripts **no longer compile for armv6**, you must manually change the files if you wish to add support.


## Default configuration

The script is configured to produce the smallest binary possible, with Curl being configured only to support HTTP and HTTPS protocols (no FTP, DICT, FILE, etc).

Make sure you take a peek at `build.sh` and change the vars according to your needs.


## Using on your project

After you've compiled the project, all you need to do is include one of the generated `*.a` files (the universal, i386 or armv7) on your project and all the headers. The `*.a` files can be found on `lib/` folder and the header files under `include/`.

When you add the files to the Xcode project, Xcode will automatically add the library files to the link build stage, i.e. you just need to add the `*.a` and `*.h` files to your project and it'll all work.

### Required frameworks

You need to add the following frameworks:

- `libz.dylib`
- `Security.framework`


## Optimizing for space on your apps

The scripts generates three binary files:

1. One with all the architectures combined (i386 and armv7), recommended for iOS development (runs both on simulator and phones);
2. One with just i386, to use on OSX development;
3. One with just armv7, to use on phones;

When you're about to build the final release (to submit to the app store), you should use the third one, as it is slightly smaller in size.

> **ProTip™**  
> Use different build targets, and include different variations of the above files in each of them so this process is automatic.


## Acknowledgments

These scripts are based on the excellent work of [Felix Schulze (x2on)](https://github.com/x2on), with some help from [Bob](http://stackoverflow.com/questions/9039554/using-libcurl-on-ios-5-as-an-alternative-to-nsurlconnection/9528936#9528936).

Also huge thanks to [Jonas Schnelli](https://github.com/jonasschnelli) for the pull request that included native Darwin SSL support.