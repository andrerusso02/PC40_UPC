
import subprocess
import sys
from os import listdir


dir = ""
n_iter = 0

# get directory to find executables in, and the number of iterations from arguments

if len(sys.argv) == 3:
    dir = sys.argv[1]
    n_iter = int(sys.argv[2])
else:
    print("Usage: python benchmark.py <dir> <n_iter>")
    sys.exit(1)

print("N; threads; time")

# get all names of executables in dir
for e in listdir(dir):
    # run each executable n_iter times
    t_arevage = 0.0
    N=0
    n_threads=0
    for i in range(n_iter):
        # print advancement clearing last line
        print(f"\radvancement {i+1}/{n_iter}", end="")
        # run executable and add time to average
        cmd = "upcrun " + dir + "/" + e
        # Run the command and get the output
        output = subprocess.run(cmd, stdout=subprocess.PIPE, shell=True)
        # print the last line of output
        last_line = output.stdout.decode("utf-8").splitlines()[-1]
        N=last_line.split(",")[0]
        n_threads=last_line.split(",")[1]
        t_arevage += float(last_line.split(",")[2])
    print("\r" + N + ";" + n_threads + "; " + str(t_arevage / n_iter))
