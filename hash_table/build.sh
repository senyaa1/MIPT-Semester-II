#!/bin/sh


mkdir -p build
pushd .
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build .
popd

hyperfine build/hash_table

perf record -g -b ./build/hash_table 
perf report -Mintel --call-graph
