import random
import subprocess
import sys
from pathlib import Path

_, number = sys.argv

random.seed(a=27)
output_folder = Path("input")
object_folder = Path("base_input")

try:
    output_folder.mkdir()
except FileExistsError:
    print("input folder already exists")

number = int(number)
values = set()

for x in range(number):
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

        cube_path = object_folder / "cube.rad"
        sphere_path = object_folder / "sphere.rad"
        output_path = output_folder / f"cube_sphere_{x}_{dir}.rad"

        subprocess.run(
            f"xform -rx {rx} -ry {ry} -rz {rz} -t {tx_cube} {ty_cube} {tz_cube} {str(cube_path.resolve())} > {str(output_path.resolve())}",
            shell=True,
        )
        subprocess.run(
            f"xform -t {tx_sphere} {ty_sphere} {tz_sphere} {str(sphere_path.resolve())} >> {str(output_path.resolve())}",
            shell=True,
        )
        values.add(
            (tx_cube, ty_cube, tz_cube, tx_sphere, ty_sphere, tz_sphere, rx, ry, rz)
        )

print(f"Created {len(values)} configs")
