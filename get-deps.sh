#! /bin/sh

set -ex

srcdir="$(dirname "$0")"
test -z "$srcdir" && srcdir=.

cd "$srcdir"

clone_repo_commit() {
    if test -d "$2/.git"; then
        git -C "$2" reset --hard
        git -C "$2" clean -fd
        if ! git -C "$2" checkout $3; then
            rm -rf "$2"
        fi
    else
        if test -d "$2"; then
            set +x
            echo "error: '$2' is not a Git repository"
            exit 1
        fi
    fi
    if ! test -d "$2"; then
        git clone $1 "$2"
        if ! git -C "$2" checkout $3; then
            rm -rf "$2"
            exit 1
        fi
    fi
}

download_by_hash() {
    DOWNLOAD_COMMAND="curl -Lo"
    if ! command -v $DOWNLOAD_COMMAND >/dev/null 2>&1; then
        DOWNLOAD_COMMAND="wget -O"
        if ! command -v $DOWNLOAD_COMMAND >/dev/null 2>&1; then
            set +x
            echo "error: Neither curl nor wget found"
            exit 1
        fi
    fi
    SHA256_COMMAND="sha256sum"
    if ! command -v $SHA256_COMMAND >/dev/null 2>&1; then
        SHA256_COMMAND="sha256"
        if ! command -v $SHA256_COMMAND >/dev/null 2>&1; then
            set +x
            echo "error: Cannot find sha256(sum) command"
            exit 1
        fi
    fi
    if ! test -f "$2" || ! $SHA256_COMMAND "$2" | grep $3 >/dev/null 2>&1; then
        rm -f "$2"
        mkdir -p "$2" && rm -rf "$2"
        $DOWNLOAD_COMMAND "$2" $1
        if ! $SHA256_COMMAND "$2" | grep $3 >/dev/null 2>&1; then
            set +x
            echo "error: Cannot download file '$2' by hash"
            echo "incorrect hash:"
            $SHA256_COMMAND "$2"
            rm -f "$2"
            exit 1
        fi
    fi
}

clone_repo_commit \
    https://github.com/osdev0/freestnd-c-hdrs-0bsd.git \
    deps/freestnd-c-hdrs-0bsd \
    0353851fdebe0eb6a4d2c608c5393040d310bf35

clone_repo_commit \
    https://github.com/osdev0/cc-runtime.git \
    deps/cc-runtime \
    13fe6383470f0e4982d926472448d6d3b80a851f

download_by_hash \
    https://github.com/limine-bootloader/limine/raw/c171e847d5dc1448722506c00a7217c9e199f8dc/limine.h \
    include/limine.h \
    a8a38dd0a2c3174708ecccede6cc7ed31d5f450c0601ddbd2e2246d155868856
