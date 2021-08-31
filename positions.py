import sys
import random
import subprocess

_, amount, model = sys.argv

random.seed(a=27)

amount = int(amount)
values = set()
for x in range(amount):
    tx = random.uniform(-0.5, 0.5)
    ty = random.uniform(-0.5, 0.5)

    rx = random.choice(range(0, 360, 1))
    # ry = random.choice(range(0, 360, 1))
    rz = random.choice(range(0, 360, 1))

    subprocess.run(
        f"xform -t {tx} 0 {ty} -rx {rx} -ry 0 -rz {rz} ./base_input/{model}.rad > ./input/{model}_{x}.rad",
        shell=True,
    )
    values.add((tx, ty, rx, rz))

if len(values) == amount:
    print("All values different")
else:
    print("At least a value is repeated")

print(values, len(values), amount, len(values) == amount)
