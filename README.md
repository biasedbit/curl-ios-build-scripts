Curl iOS build utility
======================

Script to build curl for iOS. Supports:

- iPhoneSimulator (i386)
- newer iPhones/iPads (arm v7/7s)

Curl version `7.27.0` and above now supports native (Dawrwin) SSL so the other alternatives (GnuTLS and OpenSSL) have been removed. The script now compiles `libcurl.a` with SSL support at no additional binary size (yay!).

To list all possible options and flags, run `./build_curl --help`.


## Default configuration

The script is configured to produce the smallest binary possible, with Curl being configured only to support HTTP and HTTPS protocols (no FTP, DICT, FILE, etc).

Run `./build_curl --help` to list out all the options.


## Using on your project

After you've compiled the project, all you need to do is include one of the generated `*.a` files (the universal, i386 or armv7) on your project and all the headers. The `*.a` files can be found on `lib/` folder and the header files under `include/`.

When you add the files to the Xcode project, Xcode will automatically add the library files to the link build stage, i.e. you just need to add the `*.a` and `*.h` files to your project and it'll all work.

### Required frameworks

You need to add the following frameworks:

- `libz.dylib`
- `Security.framework`


## Optimizing for space on your apps

The scripts generates different binary files, depending on how you configure it:

* A binary output file for each architecture
* A binary with all arm architectures together (if you compile with armv6 and armv7, you'll get a single arm binary that contains both architectures)
* A binary output file with i386 only (unless you don't build for i386)
* A binary output file with all of the architectures combined

When you're about to build the final release (to submit to the AppStore), you should use the combined arm binary. The i386 binary is only required for the simulator, so keeping it off the AppStore build means you can shave off a couple hundred KBs on your final package.

> **ProTip™**  
> Use different build targets, and include different variations of the above files in each of them so this process is automatic.


## Acknowledgments

This repository has dramatically changed over time, having begun with a bunch of shell scripts and evolving to a streamlined ruby script. The original scripts were based on the excellent work of [Felix Schulze (x2on)](https://github.com/x2on), with some help from [Bob](http://stackoverflow.com/questions/9039554/using-libcurl-on-ios-5-as-an-alternative-to-nsurlconnection/9528936#9528936).

Also **huge** thanks to [Jonas Schnelli](https://github.com/jonasschnelli) for the pull request that included native Darwin SSL support.


## License

Seriously? ...