import math
import random
import subprocess
import sys
from pathlib import Path

_, number, model = sys.argv

random.seed(a=27)
output_folder = Path("input")
camera_folder = Path("per_config")
object_folder = Path("base_input")

try:
    output_folder.mkdir()
except FileExistsError:
    print("input folder already exists")

try:
    camera_folder.mkdir()
except FileExistsError:
    print("per_config folder already exists")

number = int(number)
values = set()
for x in range(number):
    tx = random.uniform(-0.25, 0.25)
    ty = random.uniform(-0.25, 0.25)

    rx = random.choice(list(range(0, 46, 1)) + list(range(315, 360, 1)))  # pitch
    ry = random.choice(range(0, 360, 1))  # roll
    rz = random.choice(range(0, 360, 1))  # yaw

    object_path = object_folder / f"{model}.rad"
    output_path = output_folder / f"{model}_{x}.rad"

    subprocess.run(
        f"xform -t {tx} 0 {ty} -rx {rx} -ry {ry} -rz {rz} {str(object_path.resolve())} > {str(output_path.resolve())}",
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

    camera_path = camera_folder / f"{x}.rad"
    with camera_path.open("w") as f:
        f.writelines(
            [
                f"-vp {pos_x} {pos_y} {pos_z}\n",
                f"-vd {dir_x} {dir_y} {dir_z}\n",
                f"-vu {up_x} {up_y} {up_z}\n",
            ]
        )

print(f"Created {len(values)} configs")
