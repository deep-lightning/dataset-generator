# Dataset Generator

This repository contains bash and python scripts as well as Radiance configuration files in order to generate the different datasets needed for [Deep Lightning](https://github.com/deep-lightning/deep-lightning).

The main idea is to create images of the buffers needed for each scene in the dataset. These buffers include a depth map, a diffuse map, a normal map as well as local, global and indirect illumination.

## Installation

Aside from installing [python](https://www.python.org/downloads/release/python-395/), the bash scripts rely on [Radiance](https://www.radiance-online.org/), a lightning simulation tool that also needs to be installed. Info on how to install this tool can be found on their [website](https://www.radiance-online.org/download-install/installation-information).

## Usage

### How to create scenes to render

In order to create the buffers, the scenes' files need to be defined first. Our scenes consist of a [Cornell Box](raw_cornell.rad) plus one or more objects ([buddha](base_input/buddha.rad), [bunny](base_input/bunny.rad), [cube](base_input/cube.rad), [dragon](base_input/dragon.rad), [sphere](base_input/sphere.rad)) placed inside in different positions. The materials for each element are defined in a separate [file](materials.rad).

We provide two scripts that can be used for creating several scenes by placing the objects in different positions. The first one places an object in a random position while the second one places a cube and a sphere in random positions.

#### positions.py

```
> python positions.py <number> <object_name>
```

Given a positive number and the name of an object (buddha, bunny, cube, dragon or sphere) it creates that many configuration files inside a folder named `input`. Each file contains the object placed in a random position within the Cornell Box. It also creates the same amount of camera configs in a folder called `per_config`.

#### positions_cube_vs_sphere.py

```
> python positions_cube_vs_sphere.py <number>
```

Given a positive number it creates twice that many configuration files inside a folder named `input`. Each file contains a cube and a sphere placed in random positions without touching each other within the Cornell Box.

### How to create buffers

Once the scene files are defined, the buffers can be created with one of the following scripts.

#### render.sh

Loops in parallel over each scene description file (\*.rad) in a folder and creates all the buffers for it.

```
> bash render.sh <input_folder> <output_folder> <light_positions> <use_multiple_cameras> <use_caustic_photon_map> <use_volume_photon_map>
```

where
| argument | description | valid values | default | notes |
| -------- | ----------- | ------------ | ------- | ----- |
| `<input_folder>` | folder path than contains the scene files | | |
| `<output_folder>` | folder path to store the buffers for each scene. It's created if it doesn't exist. | | |
| `<light_positions>`| list of possible light positions separated with spaces. | up, down, left, right, back | "up" |
| `<use_multiple_cameras>` | whether to use multiple cameras. | yes, no | no |
| `<use_caustic_photon_map>` | whether to create a caustic photon map | "cpm" or nothing | | not used as our scenes contained only diffuse objects
| `<use_volume_photon_map>` | whether to create a volume photon map | "vpm" or nothing | | not used as our scenes didn't have any fog/mist

#### render_with_times.sh

Loops over each scene description file (\*.rad) in a folder and creates all the buffers for it. It also measures the total time taken for each buffer in miliseconds.

```
> bash render_with_times.sh <input_folder> <output_folder> <light_positions> <use_multiple_cameras> <use_caustic_photon_map> <use_volume_photon_map>
```

where the arguments are the same as `render.sh`.

## Dataset

After running either of the scripts defined [here](#how-to-create-buffers), the following structure should be obtained

```
<output_folder>/
    <sample_1>/
        diffuse.hdr
        local.hdr
        normal.hdr
        z.hdr
        global.hdr
        indirect.hdr
    ...
    <sample_n>/
        diffuse.hdr
        local.hdr
        normal.hdr
        z.hdr
        global.hdr
        indirect.hdr
```

### Available datasets

The datasets used in this project were also uploaded to [activeloop's hub](https://www.activeloop.ai/). For instructions on how to download them check [here](https://github.com/deep-lightning/deep-lightning/#available-datasets).

| Dataset name                                                              | Size | Description                                                                                                                          | Compatible data_regex   |
| ------------------------------------------------------------------------- | ---- | ------------------------------------------------------------------------------------------------------------------------------------ | ----------------------- |
| [vanilla](https://app.activeloop.ai/deep-lightning/vanilla)               | 10k  | Cornell Box with an object (bunny, buddha, cube, dragon and sphere) placed in different positions                                    | vanilla, positions, all |
| [camera-variant](https://app.activeloop.ai/deep-lightning/camera-variant) | 4k   | Cornell Box with both an object (bunny and buddha) and the camera placed in different positions                                      | cameras, all            |
| [light-variant](https://app.activeloop.ai/deep-lightning/light-variant)   | 4k   | Cornell Box with both an object (bunny and buddha) and the light placed in different positions                                       | lights, all             |
| [wall-variant](https://app.activeloop.ai/deep-lightning/wall-variant)     | 4k   | Cornell Box with two color combinations (red/greed and yellow/violet) and an object (bunny and buddha) placed in different positions | walls, all              |
| [object-variant](https://app.activeloop.ai/deep-lightning/object-variant) | 4k   | Cornell Box with a cube and a sphere placed in different positions                                                                   | objects, all            |
