import sys
import random
import subprocess

_, amount = sys.argv

random.seed(a=27)

amount = int(amount)
values = set()

for x in range(amount):
    for dir in ("horizontal", "vertical"):

        mult = 1 if random.random() > 0.5 else -1
        if dir == "vertical":
            # important axis
            tz_cube = mult * random.uniform(0.25, 0.5)
            tz_sphere = mult * random.uniform(-0.25, -0.5)

            # remaining axis
            tx_cube = random.uniform(-0.25, 0.25)
            tx_sphere = random.uniform(-0.25, 0.25)
        else:
            # important axis
            tx_cube = mult * random.uniform(0.25, 0.5)
            tx_sphere = mult * random.uniform(-0.25, -0.5)

            # remaining axis
            tz_cube = random.uniform(-0.25, 0.25)
            tz_sphere = random.uniform(-0.25, 0.25)

        ty_cube = random.uniform(-0.25, 0.25)
        ty_sphere = random.uniform(-0.25, 0.25)

        rx = random.choice(list(range(0, 46, 1)) + list(range(315, 360, 1)))  # pitch
        ry = random.choice(range(0, 360, 1))  # roll
        rz = random.choice(range(0, 360, 1))  # yaw

        subprocess.run(
            f"xform -rx {rx} -ry {ry} -rz {rz} -t {tx_cube} {ty_cube} {tz_cube} ./base_input/cube.rad > ./input/cube_sphere_{x}_{dir}.rad",
            shell=True,
        )
        subprocess.run(
            f"xform -t {tx_sphere} {ty_sphere} {tz_sphere} ./base_input/sphere.rad >> ./input/cube_sphere_{x}_{dir}.rad",
            shell=True,
        )
        values.add(
            (tx_cube, ty_cube, tz_cube, tx_sphere, ty_sphere, tz_sphere, rx, ry, rz)
        )

if len(values) == amount * 2:
    print("All values different")
else:
    print("At least a value is repeated")

# print(values, len(values), amount, len(values) == amount)
