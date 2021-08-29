PATH=$PATH:./radiance/bin
cat /etc/issue
rpict -version

# $1 mode
# $2 path
function filter {
    pfilt -m .25 -x /2 -y /2 $2/$1.unf > $2/$1.hdr
}

function render {

    if [ $1 == "diffuse" ]; then
      scene=$meta/scene_wo_light.oct
    else
      scene=$meta/scene.oct
    fi

    rpict ${use_gpm} ${use_cpm} ${use_vpm} @config/$1 -z $meta/$1.zbf $scene > $meta/$1.unf
    filter $1 $meta
    convert $meta/$1.hdr $path/$1.png
}

# $1 file
# $2 output directory
# $3 if needs caustic photon map
# $4 if needs volume photon map
function loop {
    filename=${1##*/}       # remove until /
    name=${filename%.rad}   # remove trailing .rad
    path="$2/$name"
    mkdir -p $path

    meta="meta/$name"
    mkdir -p $meta

    oconv materials.rad cornell_light.rad cornell.rad $1 > $meta/scene.oct
    oconv materials.rad cornell.rad $1 > $meta/scene_wo_light.oct

    make_gpm="-apg $meta/global_photon_map.gpm 5k"
    use_gpm="-ap $meta/global_photon_map.gpm 50"
    if [ "$3" = "cpm" ]; then
      echo "Using caustic photon map"
      make_cpm="-apc $meta/caustic_photon_map.vpm 5k"
      use_cpm="-ap $meta/caustic_photon_map.vpm 50"
    fi
    if [ "$4" = "vpm" ]; then
      echo "Using volume photon map"
      make_vpm="-apv $meta/volume_photon_map.vpm 5k -ma 1 1 1 -mg 1"
      use_vpm="-ap $meta/volume_photon_map.vpm 50"
    fi

    echo "Generating photon maps"
    mkpmap ${make_gpm} ${make_cpm} ${make_vpm} -t 60 $meta/scene.oct

    echo "Generating diffuse map"
    render "diffuse"

    echo "Generating local illumination"
    render "local"

    echo "Generating global illumination"
    render "global"

    echo "Generating depth buffer"
    pvalue -h `getinfo -d < $meta/global.unf` -r -b -df $meta/global.zbf | falsecolor -lw 0 -m 1 -s 10 -l Meters -r v -g v -b v > $meta/z.unf
    filter "z" $meta
    Ra_bmp $meta/z.hdr > $meta/z.bmp
    convert $meta/z.bmp $path/z.png

    echo "Generating normal buffer"
    vwrays -ff $meta/global.unf | rtrace -w -ffa -on $meta/scene.oct > $meta/normal.pts
    getinfo -c rcalc -oa -e '$1=($1+1)/2;$2=($2+1)/2;$3=($3+1)/2' < $meta/normal.pts | pvalue -r -da `getinfo -d < $meta/global.unf` > $meta/normal.unf
    filter "normal" $meta
    Ra_bmp $meta/normal.hdr > $meta/normal.bmp
    convert $meta/normal.bmp $path/normal.png

    # cleanup
    rm -r $meta
}

# $1 input folder
# $2 output folder
n=0
N=15
for file in $1/*.rad
do
  if [ "$n" -eq "$N" ]; then
    wait
    n=0
  fi
    echo $file
    loop $file $2 $3 $4 &
    n=$(( n + 1 ))
done
wait