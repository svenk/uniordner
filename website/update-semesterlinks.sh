#!/bin/bash

ALL_FILES=(mirror/*)
for x in "${ALL_FILES[@]}";
	# filter out non-semester entries
	do (test -d "$x") && (echo "$x" | grep -q "[WS]S") || continue
	target=$(echo "$x" | sed 's/.*\([WS]S\) \([0-9]*\).*/\1\2/' | awk '{print tolower($0)}')
	# check if already exists
	test -f "$target" && echo "$x -> $target exists already." && continue
	ln -sv "$x" "$target";
done;

