#!/bin/bash

ORIGINAL_DIR=${ORIGINAL_DIR:-net-next/drivers/net/ovpn}
MODIFIED_DIR="drivers/net/ovpn"

if [[ $ORIGINAL_DIR =~ ^/ ]]; then
	substr="${ORIGINAL_DIR:1}"
	ESCAPED_ORIGINAL_DIR="${substr//\//\\\/}"
else
	ESCAPED_ORIGINAL_DIR="${ORIGINAL_DIR//\//\\\/}"
fi
ESCAPED_MODIFIED_DIR="${MODIFIED_DIR//\//\\\/}"

rm -f temp.patch

for filepath in "$ORIGINAL_DIR"/*; do
    base=$(basename "$filepath")
    if [ -f "$MODIFIED_DIR/$base" ]; then
        git diff --no-index "$filepath" "$MODIFIED_DIR/$base" >> temp.patch
    fi
done

sed -i "s/$ESCAPED_ORIGINAL_DIR/$ESCAPED_MODIFIED_DIR/" temp.patch
