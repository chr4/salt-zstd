{% if grains['osrelease'] | float >= 18.04 %}
zstd:
  pkg.installed: []

{% else %}
# Versions prior Ubuntu 18.04 do not provide a recent version of zstd (at least version 1.1.2)
#
# The packaged zstd-0.5.x creates a file even when the input is not valid.
# This is a problem, as extracted wal archives need to be valid archive files.
#
# Also, the packaged version from zesty requires a more recent libc, so using the zesty
# packages is no option.
#
# Unfortunately, we'll have to build zstd from source...
{% set zstd_version = '1.3.1' %}

# Make sure packaged version is not installed
zstd_purge_old:
  pkg.purged:
    - pkgs: [zstd, libzstd1]

# Install build dependencies while crying because bloat on production
zstd_build_dependencies:
  pkg.installed:
    - pkgs: [build-essential, curl]

zstd_compile_and_install_from_source:
  cmd.run:
    - creates: /usr/local/bin/zstd
    - cwd: /tmp
    - name: |
        curl -L https://github.com/facebook/zstd/archive/v{{ zstd_version }}.tar.gz |tar -zx
        cd zstd-{{ zstd_version }}
        dir=$(pwd)

        # Compile and install ztsd
        make
        cp zstd /usr/local/bin

        # Cleanup
        cd
        if [ -n "$dir" ]; then
          rm -r "$dir"
        fi
    - require:
      - pkg: zstd_purge_old
      - pkg: zstd_build_dependencies
{% endif %}
