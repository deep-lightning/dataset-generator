# Dataset Generator

## Here you'll find:
Radiance configuration files and bash scripts to generate the dataset used in https://github.com/proyecto-grado/deep-lightning.

- Cornell Boxes with one object in different positions inside: bunny, buddha, dragon, cube and sphere.

## How to run it:

You'll need to run the following on your terminal:
- sh render.sh base_input output_folder

### In case you want to use the network with indirect illumination:
After generating the dataset, run:
- python generateIndirect.py

That script will substract the direct illumination to the global illumination.

And after having the output of the network, run:
- python generateGlobal.py

That script will add the direct illumination (given as input) to the indirect illumination (generated by the network).
