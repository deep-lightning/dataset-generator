# $1 mode
# $2 path
function render {
    rpict @config/$1 -z $2/$1.zbf $2/scene.oct > $2/$1.unf
    pfilt -m .25 -x /8 -y /8 $2/$1.unf > $2/$1.hdr
    convert $2/$1.hdr $3/$1.png
}

function loop {
    filename=${1##*/}       # remove until /
    name=${filename%.rad}   # remove trailing .rad
    path="$2/$name"
    mkdir -p $path

    meta="meta/$name"
    mkdir -p $meta

    oconv materials.rad cornell_light.rad cornell.rad $1 > $meta/scene.oct
    
    echo "Generating diffuse map"
    render "diffuse" $meta $path

    echo "Generating local illumination"
    render "local" $meta $path

    echo "Generating global illumination"
    render "global" $meta $path

    echo "Generating depth buffer"
    DIM=`getinfo -d < $meta/global.unf`
    Y_aux=${DIM#*Y }
    Y=${Y_aux%% +X*}
    X=${DIM##* }
    
    eval "pvalue -h $DIM -r -b -df $meta/global.zbf | falsecolor -m 1 -s 8 -l Meters -r v -b v -g v > $meta/z.hdr"
    Ra_bmp $meta/z.hdr > $meta/z.bmp
    eval "convert $meta/z.bmp -crop ${X}x${Y}+100 -scale 256x256 $path/z.png"

    echo "Generating normal buffer"
    vwrays -ff $meta/global.hdr | rtrace -w -ffa -on $meta/scene.oct > $meta/normal.pts
    getinfo -c rcalc -oa -e '$1=($1+1)/2;$2=($2+1)/2;$3=($3+1)/2' < $meta/normal.pts | pvalue -r -da `getinfo -d < $meta/global.hdr` > $meta/normal.hdr
    Ra_bmp $meta/normal.hdr > $meta/normal.bmp
    convert $meta/normal.bmp $path/normal.png
}

# $1 input folder
# $2 output folder
for file in $1/*.rad
do
    echo $file
    loop $file $2 &
done
wait