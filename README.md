Curl build utility for iOS and OSX
==================================

Script to build curl for iOS 5+ and OSX 10.7+. Supports:

- Mac OSX (i386-osx)
- iPhoneSimulator (i386-sim)
- newer iPhones/iPads/iPods (arm v7/7s)

Curl version `7.27.0` and above now supports native (Darwin) SSL so the other alternatives (GnuTLS and OpenSSL) have been removed. The script now compiles `libcurl.a` with SSL support at no additional binary size (yay!).

To list all possible options and flags, run `./build_curl --help`.

> **NOTE:**  
> These scripts require Ruby 1.9. Check out the `ruby1.8` branch if you're still running 1.8.


## Default configuration

The script is configured to produce the smallest binary possible, with Curl being configured only to support HTTP and HTTPS protocols (no FTP, DICT, FILE, etc).

Run `./build_curl --help` to list out all the options.


## Packages

The scripts can generate different binary files with support for different platforms (and architectures within those platforms) depending on how you configure it. Check out the `--archs` flag on the help (`./build_curl --help`) for all available options.

By default it will compile for all architectures, generating the following "packages":

1. **iOS development**

    A binary output file for iOS that combines i386 (simulator) and both arm architectures, perfect for development on the simulator and phones.

    Can be found under `<output>/curl/ios-dev/`.

2. **iOS distribution**

    A binary output file for iOS that combines **only** arm architectures, ideal for the publishing stage of your application.

    When you're about to build the final release of your iOS app (to submit to the App Store), you should use this binary. i386 support is only required for the simulator, so keeping it off the AppStore build means you can shave off a couple hundred KBs on your final package.

    Can be found under `<output>/curl/ios-distribution/`.

3. **OSX development/distribution**

    A binary output file for OSX, works both for development and distribution to the Mac App Store.

    Can be found under `<output>/curl/osx/`.

If you build for a subset of the architectures, the packages will still be created with the available architectures unless they would be empty. What this means is that, e.g.:

* if you specify `--archs i386-sim` the script will generate package 1 but it won't contain arm support &mdash; it will not generate packages 2 and 3;
* if you specify `--archs i386-osx` the script will only generate package 3;
* if you specify `--archs armv7s` the script will generate both package 1 and 2, but both will only support armv7s.

> **ProTip™**  
> Use different build targets, and include different variations of these packages in each of them so this process is automatic.


## Using on your project

After you've compiled the project, all you need to do is include one of the generated packages (its `lib` and `include` folders) files on your project.

When you add the files to the Xcode project, Xcode will automatically add the library files to the link build stage, i.e. you just need to add the `*.a` and `*.h` files to your project and it'll all work.


### Required frameworks

You need to add the following frameworks:

- `libz.dylib`
- `Security.framework`


## Acknowledgments

This repository has dramatically changed over time, having begun with a bunch of shell scripts and evolving to a streamlined ruby script. The original scripts were based on the excellent work of [Felix Schulze (x2on)](https://github.com/x2on), with some help from [Bob](http://stackoverflow.com/questions/9039554/using-libcurl-on-ios-5-as-an-alternative-to-nsurlconnection/9528936#9528936).

Also huge thanks to [Jonas Schnelli](https://github.com/jonasschnelli) for the pull request that included native Darwin SSL support.


## License

Seriously? ...
