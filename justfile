##
# Build Tasks
##

cache_dir := justfile_directory() + "/cache"
chk_dir   := justfile_directory() + "/chk"
tmp_dir   := "/tmp/wp-core-checksums"



# Build and Clean.
default: build clean


# Build!
@build: _prereq
	just _download-list
	just _download-cores
	just _hash-cores

	# Generate a version list.
	find "{{ chk_dir }}" -name '*.md5' -type f -exec basename {} \; | sed 's/.md5//g' | sort -u > "{{ justfile_directory() }}/versions.txt"

	# Fix permissions (in case of Docker, etc.)
	just _fix-chown "{{ cache_dir }}"
	just _fix-chown "{{ chk_dir }}"

	# Cleanup.
	[ ! -f "{{ tmp_dir }}/list.txt" ] || rm "{{ tmp_dir }}/list.txt"

	echo "Success! All checksums have been generated."


# Clean Cache.
@clean: _prereq
	find "{{ cache_dir }}" -type f -delete


# Fetch Release List.
_download-list:
	#!/usr/bin/env bash

	# Already have it?
	if [ -f "{{ tmp_dir }}/list.txt" ]; then
		exit 0
	fi

	echo "Fetching Release List"

	# Download!
	wget -q -O- https://wordpress.org/download/releases/ | \
		grep -oh -E '"https://wordpress.org/wordpress-[0-9.a-zA-Z-]+.zip"' | \
		grep -v IIS | \
		grep -v '\-mu\-' | \
		sed 's/"//g' | \
		sort -u > "{{ tmp_dir }}/list2.txt"

	# Compare with what we already have.
	[ ! -f "{{ tmp_dir }}/list.txt" ] || rm "{{ tmp_dir }}/list.txt"
	while read URL; do
		FILE="$( basename "$URL" )"
		VERSION="${FILE%%.zip}"
		VERSION="${VERSION:10}"
		if [ ! -f "{{ chk_dir }}/$VERSION.md5" ]; then
			echo "$URL" >> "{{ tmp_dir }}/list.txt"
		fi
	done <"{{ tmp_dir }}/list2.txt"

	# Clean up.
	rm "{{ tmp_dir }}/list2.txt"

	exit 0


# Fetch Packages.
_download-cores:
	#!/usr/bin/env bash

	# Already have everything?
	if [ ! -f "{{ tmp_dir }}/list.txt" ]; then
		exit 0
	fi

	echo "Fetching Core Packages"

	while read URL; do
		FILE="$( basename "$URL" )"
		VERSION="${FILE%%.zip}"
		VERSION="${VERSION:10}"
		if [ ! -f "{{ cache_dir }}/$VERSION.zip" ]; then
			echo "    Downloading $VERSION"
			wget -q -O "{{ cache_dir }}/$VERSION.zip" "$URL"
			wget -q -O "{{ cache_dir }}/$VERSION.md5" "$URL.md5"
			md5sum "{{ cache_dir }}/$VERSION.zip" | grep -q "$( cat "{{ cache_dir }}/$VERSION.md5" )"
			if [ $? -ne 0 ]; then
				echo "The archive did not match its own checksum!"
				exit 1
			fi
		fi
	done <"{{ tmp_dir }}/list.txt"

	exit 0


# Generate the Hashes!
_hash-cores:
	#!/usr/bin/env bash

	# Already have everything?
	if [ ! -f "{{ tmp_dir }}/list.txt" ]; then
		exit 0
	fi

	while read URL; do
		FILE="$( basename "$URL" )"
		VERSION="${FILE%%.zip}"
		VERSION="${VERSION:10}"
		if [ -f "{{ cache_dir }}/$VERSION.zip" ]; then
			just _hash-core "$VERSION"
		fi
	done <"{{ tmp_dir }}/list.txt"

	exit 0


# Generate the Hashes (Single)!
_hash-core VERSION:
	#!/usr/bin/env bash

	if [ ! -f "{{ cache_dir }}/{{ VERSION }}.zip" ]; then
		echo "Invalid version: {{ VERSION }}"
		exit 1
	fi

	# Skip it? If we already have all the checksums, there's nothing to do.
	if [ -f "{{ chk_dir }}/{{ VERSION }}.b3" ]; then
		if [ -f "{{ chk_dir }}/{{ VERSION }}.md5" ]; then
			if [ -f "{{ chk_dir }}/{{ VERSION }}.sha256" ]; then
				if [ -f "{{ chk_dir }}/{{ VERSION }}.sha512" ]; then
					exit 0
				fi
			fi
		fi
	fi

	echo "    Hashing {{ VERSION }}"

	# Unpack it.
	[ ! -d "{{ tmp_dir }}/extract" ] || rm -rf "{{ tmp_dir }}/extract"
	mkdir "{{ tmp_dir }}/extract"
	unzip -q "{{ cache_dir }}/{{ VERSION }}.zip" -d "{{ tmp_dir }}/extract"
	ROOT="$( find "{{ tmp_dir }}/extract/" -mindepth 1 -maxdepth 1 -type d | head -n 1 )"

	if [ -n "$ROOT" ]; then
		# Get rid of bundled plugins and themes, and the sample config.
		[ ! -f "$ROOT/wp-config-sample.php" ] || rm "$ROOT/wp-config-sample.php"
		if [ -d "$ROOT/wp-content/plugins" ]; then
			if [ -f "$ROOT/wp-content/plugins/index.php" ]; then
				mv "$ROOT/wp-content/plugins/index.php" "{{ tmp_dir }}/index.php"
				rm -rf "$ROOT/wp-content/plugins"
				mkdir "$ROOT/wp-content/plugins"
				mv "{{ tmp_dir }}/index.php" "$ROOT/wp-content/plugins/index.php"
			else
				rm -rf "$ROOT/wp-content/plugins"
			fi
		fi
		if [ -d "$ROOT/wp-content/themes" ]; then
			if [ -f "$ROOT/wp-content/themes/index.php" ]; then
				mv "$ROOT/wp-content/themes/index.php" "{{ tmp_dir }}/index.php"
				rm -rf "$ROOT/wp-content/themes"
				mkdir "$ROOT/wp-content/themes"
				mv "{{ tmp_dir }}/index.php" "$ROOT/wp-content/themes/index.php"
			else
				rm -rf "$ROOT/wp-content/themes"
			fi
		fi

		cd "$ROOT"

		# Generate checksums.
		find . -type f -print0 | sort -z | xargs -0 b3sum > "{{ chk_dir }}/{{ VERSION }}.b3"
		find . -type f -print0 | sort -z | xargs -0 md5sum > "{{ chk_dir }}/{{ VERSION }}.md5"
		find . -type f -print0 | sort -z | xargs -0 sha256sum > "{{ chk_dir }}/{{ VERSION }}.sha256"
		find . -type f -print0 | sort -z | xargs -0 sha512sum > "{{ chk_dir }}/{{ VERSION }}.sha512"

		# Strip leading ./ from paths.
		sd -s " ./" " " "{{ chk_dir }}/{{ VERSION }}.b3"
		sd -s " ./" " " "{{ chk_dir }}/{{ VERSION }}.md5"
		sd -s " ./" " " "{{ chk_dir }}/{{ VERSION }}.sha256"
		sd -s " ./" " " "{{ chk_dir }}/{{ VERSION }}.sha512"
	fi

	cd "{{ justfile_directory() }}"
	rm -rf "{{ tmp_dir }}/extract"

	exit 0


# Setup and Requirements Checks.
_prereq:
	#!/usr/bin/env bash

	[ -d "{{ cache_dir }}" ] || mkdir "{{ cache_dir }}"
	[ -d "{{ chk_dir }}" ] || mkdir "{{ chk_dir }}"
	[ -d "{{ tmp_dir }}" ] || mkdir "{{ tmp_dir }}"

	if [ ! -d "{{ tmp_dir }}" ]; then
		echo "Missing tmp dir!"
		exit 1
	fi

	if [ -z "$( command -v b3sum)" ]; then
		if [ -n "$( command -v cargo )" ]; then
			cargo install b3sum
		fi
	fi

	just _prereq-app b3sum || exit 1
	just _prereq-app md5sum || exit 1
	just _prereq-app sha256sum || exit 1
	just _prereq-app sha512sum || exit 1
	just _prereq-app sd || exit 1
	just _prereq-app wget || exit 1

	exit 0


# Make Sure Required App Exists.
_prereq-app BIN:
	#!/usr/bin/env bash

	if [ -z "$( command -v {{ BIN }} )" ]; then
		echo "Missing {{ BIN }}."
		exit 1
	fi

	exit 0


# Fix file/directory ownership.
@_fix-chown PATH:
	[ ! -e "{{ PATH }}" ] || chown -R --reference="{{ justfile() }}" "{{ PATH }}"
