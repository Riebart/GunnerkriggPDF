#!/bin/bash

# Get the number of comics currently published
current_comic_number=$(wget -qO- 'https://www.gunnerkrigg.com' | grep -oE "/comics/[0-9]+.jpg" | tr '.' '/' | cut -d '/' -f3 | sed 's/^0*//')

# Download every comic until now
seq -w 00000001 $current_comic_number | while read comic_number
do
    echo "https://www.gunnerkrigg.com/comics/$comic_number.jpg"
done | wget -q -nc -i -

# Now get all of the captures, and the page numbers per chapter, as well as chapter names
chapter_names=$(wget -qO- 'https://www.gunnerkrigg.com/archives/' | grep -oP '<h4>(?!Welcome to Gunnerkrigg Court)[^<]*</h4>' | sed 's|</*h4>||g;s/:/ -/' | tr ' ' '_' | tr -d '.')

# Chapter start pages
start_pages=$(wget -qO- 'https://www.gunnerkrigg.com/archives/' | grep -oP 'chapter_button.*href=[^>]*>' | sed 's/^.*href=".*p=\([^"]*\)".*$/\1/')

# Calculate the page range pairings
# Add 1 to the current comic number, because we treat that second column as "the first page of the
# next chapter" in the following while loop
ranges="$(paste <(echo "$start_pages" | head -n -1) <(echo "$start_pages" | tail -n +2))
$(echo "$start_pages" | tail -n1) $[current_comic_number+1]"

paste <(echo "$chapter_names") <(echo "$ranges") | while read name first next_first
do
    last=$[next_first-1]
    out_name="$(echo "$name" | tr '_' ' ')"
    echo "$out_name"
    convert $(printf "%08d.jpg " `seq $first $last | paste -sd ' '`) "$out_name.pdf"
done
