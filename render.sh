# $1 mode
# $2 path
# $3 if needs caustic photon map
# $4 if needs volume photon map

function filter {
    pfilt -m .25 -x /2 -y /2 $2/$1.unf > $2/$1.hdr
}

function render {
    rpict -ab 1 ${use_gpm} ${use_cpm} ${use_vpm} @config/$1 -z $2/$1.zbf $2/scene.oct > $2/$1.unf
    filter $1 $2
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
    oconv materials.rad cornell.rad $1 > $meta/scene_wo_light.oct

    make_gpm="-apg $meta/global_photon_map.gpm 5k"
    use_gpm="-ap $meta/global_photon_map.gpm 50"
    if [ "$2" = "cpm" ]; then
      echo "Using caustic photon map"
      make_cpm="-apc $meta/caustic_photon_map.vpm 5k"
      use_cpm="-ap $meta/caustic_photon_map.vpm 50"
    fi
    if [ "$3" = "vpm" ]; then
      echo "Using volume photon map"
      make_vpm="-apv $meta/volume_photon_map.vpm 5k -ma 1 1 1 -mg 1"
      use_vpm="-ap $meta/volume_photon_map.vpm 50"
    fi

    echo "Generating photon maps"
    mkpmap ${make_gpm} ${make_cpm} ${make_vpm} -t 60 $meta/scene.oct

    echo "Generating diffuse map"
    rpict -ab 1 ${use_gpm} ${use_cpm} ${use_vpm} @config/diffuse -z $meta/diffuse.zbf $meta/scene_wo_light.oct > $meta/diffuse.unf
    filter "diffuse" $meta
    convert $meta/diffuse.hdr $path/diffuse.png

    echo "Generating local illumination"
    render "local" $meta $path

    echo "Generating global illumination"
    render "global" $meta $path

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
for file in $1/*.rad
do
    echo $file
    loop $file $2 $3 $4 &
done
wait