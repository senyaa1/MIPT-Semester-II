#!/bin/sh

cd hash_table
./build.sh
cd ..

cd hash_table_old
./build.sh
cd ..

hyperfine hash_table/build/hash_table hash_table_old/build/hash_table -w 3 -m 30

