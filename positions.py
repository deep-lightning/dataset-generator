import sys
import random

_, amount, model = sys.argv

random.seed(a=27)

for x in range(int(amount)):
    tx = random.random() / 2 - 0.25
    ty = random.random() / 2 - 0.25
    tz = random.random() / 2 - 0.25

    rx = random.choice(range(0,360,1))
    ry = random.choice(range(0,360,1))
    rz = random.choice(range(0,360,1))

    with open(f"{model}_{x}.rad", "w") as text_file:
        text_file.write(f"dragon mesh dragon\n11 ./{model}.rtm -t {tx} {ty} {tz} -rx {rx} -ry {ry} -rz {rz}\n0\n0")