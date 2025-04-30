#!/bin/bash

ORIGINAL_DIR="net-next/drivers/net/ovpn"
MODIFIED_DIR="drivers/net/ovpn"

rm -f temp.patch

for filepath in "$ORIGINAL_DIR"/*; do
    base=$(basename "$filepath")
    if [ -f "$MODIFIED_DIR/$base" ]; then
        git diff --no-index "$filepath" "$MODIFIED_DIR/$base" >> temp.patch
    fi
done

sed -i 's/net-next\///' temp.patch
