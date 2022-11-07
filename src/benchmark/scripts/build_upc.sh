# build all upc programs of a directory using the upc compiler

# list of number of threads
THREADS="2 4 8 16"

for t in $THREADS
do
    for i in `ls $1/*.upc`
    do
        cmd=(upcc $i -T=${t} -network=smp -o  $1/out/`basename $i .upc`_T${t})
        echo "running ${cmd[@]}"
        ${cmd[@]}
    done
done