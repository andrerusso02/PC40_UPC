
import subprocess
import sys


cmd = ""
n_iter = 0

# get the command to run and the number of iterations from arguments

if len(sys.argv) == 3:
    cmd = sys.argv[1]
    n_iter = int(sys.argv[2])
else:
    print("Usage: python benchmark.py <command> <n_iter>")
    sys.exit(1)

arevage_duration = 0
for i in range(int(n_iter)):
    # print advancement clearing last line
    print(f"\radvancement {i+1}/{n_iter}...", end="")
    # Run the command and get the output
    output = subprocess.run(cmd, stdout=subprocess.PIPE)
    # Get the duration of the command
    duration = output.stdout.decode("utf-8").split(" ")[-1]
    # Add the duration to the average duration
    arevage_duration += float(duration)

# Print the average duration
print("\nAverage duration : ", arevage_duration / int(n_iter))

    