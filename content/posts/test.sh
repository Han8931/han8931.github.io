#!/bin/bash

shopt -s nullglob
for file in 20????????_*.md; do
  new=$(awk -v f="$file" 'BEGIN{
    n=f
    sub(/^[0-9]{8}_/, "", n)   # drop leading date_
    gsub(/_/, "-", n)          # underscores -> hyphens
    print n
  }')
  [[ $file != "$new" ]] && mv -- "$file" "$new"
done
