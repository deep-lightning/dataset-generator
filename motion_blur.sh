# Run as:
# sh motion_blur.sh input_folder
#
# This script will give you an effect of motion blur to the images inside the input_folder
#

mkdir "output-motion-blur"
for file in $1/*.png
do
  filename=${file#*/}
  echo $filename
  convert -size 70x70 -channel RGBA $file -motion-blur 0x7+45 output-motion-blur/$filename
done