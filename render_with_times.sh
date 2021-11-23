PATH=$PATH:./radiance/bin
cat /etc/issue
rpict -version

# $1 mode
# $2 path
function filter {
    pfilt -1 -x /16 -y /16 $meta/$1.unf > $path/$1.hdr
}

function render {

    if [ $1 == "diffuse" ]; then
      scene=$meta/scene_wo_light.oct
    else
      scene=$meta/scene.oct
    fi

    if [ $2 == "no" ]; then
      rpict ${use_gpm} ${use_cpm} ${use_vpm} @config/$1 -z $meta/$1.zbf $scene > $meta/$1.unf
    else
      rpict ${use_gpm} ${use_cpm} ${use_vpm} @config/$1 @per_config/$file_num -z $meta/$1.zbf $scene > $meta/$1.unf
    fi
    filter $1
}

# $1 file
# $2 output directory
# $3 light position
# $4 multiple cameras
# $5 if needs caustic photon map
# $6 if needs volume photon map

total_pre=0
total_diffuse=0
total_local=0
total_global=0
total_normal=0
total_depth=0
total_indirect=0
function loop {
    ts=$(date +%s%N)

    filename=${1##*/}       # remove until /
    name=${filename%.rad}   # remove trailing .rad
    
    lights=($3)
    file_num=${name//[!0-9]/}
    chosen=${lights[$((file_num % ${#lights[@]}))]}
    
    path="$2/${name}_$chosen"
    mkdir -p $path

    meta="meta/${name}_$chosen"
    mkdir -p $meta

    oconv materials.rad lights/cornell_light_$chosen.rad raw_cornell.rad $1 > $meta/scene.oct
    oconv materials.rad raw_cornell.rad $1 > $meta/scene_wo_light.oct

    make_gpm="-apg $meta/global_photon_map.gpm 5k"
    use_gpm="-ap $meta/global_photon_map.gpm 50"
    if [ "$5" = "cpm" ]; then
      echo "Using caustic photon map"
      make_cpm="-apc $meta/caustic_photon_map.vpm 5k"
      use_cpm="-ap $meta/caustic_photon_map.vpm 50"
    fi
    if [ "$6" = "vpm" ]; then
      echo "Using volume photon map"
      make_vpm="-apv $meta/volume_photon_map.vpm 5k -ma 1 1 1 -mg 1"
      use_vpm="-ap $meta/volume_photon_map.vpm 50"
    fi

    echo "Generating photon maps"
    mkpmap ${make_gpm} ${make_cpm} ${make_vpm} -t 60 $meta/scene.oct
    
    total_pre=$((total_pre + ($(date +%s%N) - $ts)/1000000))

    ts=$(date +%s%N)
    echo "Generating diffuse map"
    render "diffuse" $4
    total_diffuse=$((total_diffuse + ($(date +%s%N) - $ts)/1000000))

    ts=$(date +%s%N)
    echo "Generating local illumination"
    render "local" $4
    total_local=$((total_local + ($(date +%s%N) - $ts)/1000000))

    ts=$(date +%s%N)
    echo "Generating global illumination"
    render "global" $4
    total_global=$((total_global + ($(date +%s%N) - $ts)/1000000))

    ts=$(date +%s%N)
    echo "Generating depth buffer"
    pvalue -h `getinfo -d < $meta/global.unf` -r -b -df $meta/local.zbf | falsecolor -lw 0 -m 1 -s 10 -l Meters -r v -g v -b v > $meta/z.unf
    filter "z"
    total_depth=$((total_depth + ($(date +%s%N) - $ts)/1000000))

    ts=$(date +%s%N)
    echo "Generating normal buffer"
    vwrays -ff $meta/global.unf | rtrace -w -fff -on $meta/scene.oct > $meta/normal.pts
    getinfo -c rcalc -if3 -of -e '$1=($1+1)/2;$2=($2+1)/2;$3=($3+1)/2' < $meta/normal.pts | pvalue -r -df `getinfo -d < $meta/global.unf` > $meta/normal.unf
    filter "normal"
    total_normal=$((total_normal + ($(date +%s%N) - $ts)/1000000))

    ts=$(date +%s%N)
    echo "Generating indirect buffer"
    pcomb $meta/global.unf -s -1 $meta/local.unf > $meta/indirect.unf
    filter "indirect"
    total_indirect=$((total_indirect + ($(date +%s%N) - $ts)/1000000))

    # cleanup
    rm -r $meta
}

# $1 input folder
# $2 output folder
# $3 light directions ex: up down left right back
n=0
N=1
for file in $1/*.rad
do
  # if [ "$n" -eq "$N" ]; then
  #   wait
  #   n=0
  # fi
  loop $file $2 "${3:-up}" ${4:-no} $5 $6
  n=$(( n + 1 ))
done
echo $total_pre $total_diffuse $total_local $total_global $total_normal $total_depth $total_indirect
wait