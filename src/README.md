# UPC Hands On

## Compile / run

example :
`upcc heat_4.upc -T=4 -network=smp -o heat_4`
`upcrun heat_4`

## Benchmark

To benchmark, cd to benchmark directory.
Inside benchmark, each directory except "scripts" contains a list of source files to be compiled an compiled sources in "out".

### Compile and test upc programs

#### Build
example :
Running `./scripts/build_upc.sh heat_4_bench` will commpile all upc sources contained in heat_4_bench and will compile them for 2, 4, 8 and 16 threads in heat_4_bench/out.

### Execute

example :
Running `python3 scripts/benchmark_upc.py heat_4_bench/out 10` will run 10 times each executable of heat_4_bench/out and return arevage execution time.