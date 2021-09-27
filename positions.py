import math
import sys
import random
import subprocess

_, amount, model = sys.argv

random.seed(a=27)

amount = int(amount)
values = set()
for x in range(amount):
    tx = random.uniform(-0.25, 0.25)
    ty = random.uniform(-0.25, 0.25)

    rx = random.choice(list(range(0, 46, 1)) + list(range(315, 360, 1)))  # pitch
    ry = random.choice(range(0, 360, 1))  # roll
    rz = random.choice(range(0, 360, 1))  # yaw

    subprocess.run(
        f"xform -t {tx} 0 {ty} -rx {rx} -ry {ry} -rz {rz} ./base_input/{model}.rad > ./input/{model}_{x}.rad",
        shell=True,
    )
    values.add((tx, ty, rx, rz))

    # add configs for camera
    radius = 3.41421356
    rot_hor = random.choice(range(225, 315, 1))

    pos_x = math.cos(math.radians(rot_hor)) * radius
    pos_y = math.sin(math.radians(rot_hor)) * radius
    pos_z = 0

    norm_dir = math.sqrt((pos_x ** 2 + pos_y ** 2 + pos_z ** 2))
    dir_x = -pos_x / norm_dir
    dir_y = -pos_y / norm_dir
    dir_z = -pos_z / norm_dir

    up_x = 0
    up_y = 0
    up_z = 1

    with open(f"./per_config/{x}", "w") as f:
        f.writelines(
            [
                f"-vp {pos_x} {pos_y} {pos_z}\n",
                f"-vd {dir_x} {dir_y} {dir_z}\n",
                f"-vu {up_x} {up_y} {up_z}\n",
            ]
        )

if len(values) == amount:
    print("All values different")
else:
    print("At least a value is repeated")

# print(values, len(values), amount, len(values) == amount)
