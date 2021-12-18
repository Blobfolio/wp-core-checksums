# WordPress Core File Checksums

The [`chk`](https://github.com/Blobfolio/wp-core-checksums/tree/master/chk) directory contains file checksum lists for every WordPress [release](https://wordpress.org/download/releases/) in the following formats:

* Blake3
* MD5
* SHA256
* SHA512

The checksum files can be used to verify the integrity of your Core files, similar to the [wp-cli](https://wp-cli.org/) command `wp core verify-checksums`, but without the overhead of involving PHP/MySQL.

All you need to do is:

1. Download the preferred checksum list for your WordPress version;
2. `cd` to the root directory of the WordPress installation;
3. Run the corresponding program for verifying checksums;

The syntax for #3 can vary by operating system, but usually looks like this:

```bash
# Blake3
b3sum -c /path/to/version.b3

# MD5
md5sum -c /path/to/version.md5

# SHA256
sha256sum -c /path/to/version.sha256

# SHA512
sha512sum -c /path/to/version.sha512
```
