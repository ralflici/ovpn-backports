#!/bin/bash

ORIG_SOURCES_DIR=${ORIG_SOURCES_DIR:-kernel/drivers/net/ovpn}
ORIG_TESTS_DIR=${ORIG_TESTS_DIR:-kernel/tools/testing/selftests/net/ovpn}
MOD_SOURCES_DIR="drivers/net/ovpn"
MOD_TESTS_DIR="tests/ovpn-cli"

# create the escaped version of the directories
if [[ $ORIG_SOURCES_DIR =~ ^/ ]]; then
	substr="${ORIG_SOURCES_DIR:1}"
	ESC_ORIG_SOURCES_DIR="${substr//\//\\\/}"
else
	ESC_ORIG_SOURCES_DIR="${ORIG_SOURCES_DIR//\//\\\/}"
fi

if [[ $ORIG_TESTS_DIR =~ ^/ ]]; then
	substr="${ORIG_TESTS_DIR:1}"
	ESC_ORIG_TESTS_DIR="${substr//\//\\\/}"
else
	ESC_ORIG_TESTS_DIR="${ORIG_TESTS_DIR//\//\\\/}"
fi

ESC_MOD_SOURCES_DIR="${MOD_SOURCES_DIR//\//\\\/}"
ESC_MOD_TESTS_DIR="${MOD_TESTS_DIR//\//\\\/}"

rm -f compat-patches/sources/*.patch
rm -f compat-patches/tests/*.patch

# handle the source files
for filepath in "$ORIG_SOURCES_DIR"/*; do
    base=$(basename "$filepath")
    out="compat-patches/sources/${base}.patch"
    if [ -f "$MOD_SOURCES_DIR/$base" ]; then
        git diff --no-index "$filepath" "$MOD_SOURCES_DIR/$base" > "$out"
        # if the patch is empty, remove it
        if [ ! -s "$out" ]; then
            rm -f "$out"
            continue
        fi
        sed -i "s/$ESC_ORIG_SOURCES_DIR/$ESC_MOD_SOURCES_DIR/" "$out"
    fi
done

# handle the test files
for filepath in "$ORIG_TESTS_DIR"/*; do
    base=$(basename "$filepath")
    out="compat-patches/tests/${base}.patch"
    if [ -f "$MOD_TESTS_DIR/$base" ]; then
        git diff --no-index "$filepath" "$MOD_TESTS_DIR/$base" > "$out"
        # if the patch is empty, remove it
        if [ ! -s "$out" ]; then
            rm -f "$out"
            continue
        fi
        sed -i "s/$ESC_ORIG_TESTS_DIR/$ESC_MOD_TESTS_DIR/" "$out"
    fi
done
