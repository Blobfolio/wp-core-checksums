# WordPress Core File Checksums

The [`chk`](https://github.com/Blobfolio/wp-core-checksums/tree/master/chk) directory contains file checksum lists for every WordPress [release](https://wordpress.org/download/releases/) in the following formats:

* [Blake3](https://github.com/BLAKE3-team/BLAKE3)
* MD5
* SHA256
* SHA512

The checksum files can be used to verify the integrity of your Core files, similar to the [wp-cli](https://wp-cli.org/) command `wp core verify-checksums`, but without the overhead of involving PHP/MySQL.

All you need to do is:

1. Download the preferred checksum list for your WordPress version;
2. `cd` to the root directory of the WordPress installation;
3. Run the corresponding program for verifying checksums;

## Downloading

All checksum files are named after their corresponding WordPress version, with an extension of `b3`, `md5`, `sha256`, or `sha512` denoting the hash format (Blake3, MD5, SHA256, or SHA512 hashes respectively).

The complete list of supported versions is available [here](https://raw.githubusercontent.com/Blobfolio/wp-core-checksums/main/versions.txt).

```bash
# Example:
# Download Blake3 hashes for WP 5.8.2
wget -q -O 5.8.2.b3 \
    https://raw.githubusercontent.com/Blobfolio/wp-core-checksums/main/chk/5.8.2.b3
```

Alternatively, you could clone the entire repository, but beware it is rather large; there have been a fair few WordPress releases over the years!

```bash
git clone https://github.com/Blobfolio/wp-core-checksums.git
```

## Verifying

Application syntax can vary by operating system, but usually looks like this:

```bash
# All paths are relative. Start in your WP installation's
# root directory, i.e. where wp-load.php lives.
cd /path/to/wp

# Blake3
b3sum -c /path/to/VERSION.b3

# MD5
md5sum -c /path/to/VERSION.md5

# SHA256
sha256sum -c /path/to/VERSION.sha256

# SHA512
sha512sum -c /path/to/VERSION.sha512
```
