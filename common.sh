PATH=$PATH:./radiance/bin
cat /etc/issue
rpict -version

#######################################
# Performs anti-aliasing and scaling to a high res buffer image and saves it as a .hdr image.
# Globals:
#   (uses)  meta
#   (uses)  path
# Arguments:
#   $1 -> name of buffer
# Outputs:
#   saves .hdr image with $1 name in $path folder
#######################################
function filter {
    pfilt -1 -x /16 -y /16 $meta/$1.unf > $path/$1.hdr
}

#######################################
# Renders a buffer image.
# Globals:
#   (uses)  meta
#   (uses)  file_num
#   (uses)  use_gpm
#   (uses)  use_cpm
#   (uses)  use_vpm
# Arguments:
#   $1 -> name of buffer to render
#   $2 -> yes/no string to indicate if a custom camera, based on $file_num, should be used
# Outputs:
#   creates buffer render inside $meta folder and invokes filter with $1
#######################################
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

#######################################
# Measures time of a command in miliseconds.
# Based on https://askubuntu.com/questions/1080113/measuring-execution-time-of-a-command-in-milliseconds
# Globals:
#   (modifies)  ts
#   (modifies)  elapsed
# Arguments:
#   any command with its arguments
#######################################
function timeit {
    ts=$(date +%s%N)
    "$@"
    elapsed=$((($(date +%s%N) - $ts)/1000000))
}

#######################################
# Initializes stuff needed to render the buffers such as the scene octree or photon maps.
# Globals:
#   (modifies)  file_num
#   (modifies)  path
#   (modifies)  meta
#   (modifies)  use_gpm
#   (modifies)  use_cpm
#   (modifies)  use_vpm
# Arguments:
#   $1 -> file describing a scene to process
#   $2 -> output directory
#   $3 -> list of possible light positions -> valid values: up, down, left, right, back
#   $4 -> whether to use multiple cameras -> one of: yes, no
#   $5 -> whether to create a caustic photon map -> either "cpm" or nothing
#   $6 -> whether to create a volume photon map -> either "vpm" or nothing
# Outputs:
#   creates $meta folder to store temporary files
#   creates $path folder to save the buffers 
#   creates scene octrees and photon maps inside $meta
#######################################
function setup {
    filename=${1##*/}       # remove until /
    name=${filename%.rad}   # remove trailing .rad
    
    # cycle through light positions for each scene to render in case $lights has more than one element
    lights=($3)
    file_num=${name//[!0-9]/}
    # ${#lights[@]} -> number of elements in list
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
}

#######################################
# Creates diffuse buffer image.
# Globals:
#   (uses)  meta
#   (uses)  path
#   (uses)  file_num
#   (uses)  use_gpm
#   (uses)  use_cpm
#   (uses)  use_vpm
# Arguments:
#   $1 -> whether to use multiple cameras -> one of: yes, no
# Outputs:
#   saves diffuse.hdr image in $path folder
#######################################
function create_diffuse_buffer {
    echo "Generating diffuse buffer"
    render "diffuse" $1
}

#######################################
# Creates local illumination image.
# Globals:
#   (uses)  meta
#   (uses)  path
#   (uses)  file_num
#   (uses)  use_gpm
#   (uses)  use_cpm
#   (uses)  use_vpm
# Arguments:
#   $1 -> whether to use multiple cameras -> one of: yes, no
# Outputs:
#   saves local.hdr image in $path folder
#######################################
function create_local_illum {
    echo "Generating local illumination"
    render "local" $1
}

#######################################
# Creates global illumination image.
# Globals:
#   (uses)  meta
#   (uses)  path
#   (uses)  file_num
#   (uses)  use_gpm
#   (uses)  use_cpm
#   (uses)  use_vpm
# Arguments:
#   $1 -> whether to use multiple cameras -> one of: yes, no
# Outputs:
#   saves global.hdr image in $path folder
#######################################
function create_global_illum {
    echo "Generating global illumination"
    render "global" $1
}

#######################################
# Creates depth buffer image where lighter colors mean a point is further away
# Globals:
#   (uses)  meta
#   (uses)  path
# Outputs:
#   saves z.hdr image in $path folder
#######################################
function create_depth_buffer {
    echo "Generating depth buffer"
    pvalue -h `getinfo -d < $meta/global.unf` -r -b -df $meta/global.zbf | falsecolor -lw 0 -m 1 -s 10 -l Meters -r v -g v -b v > $meta/z.unf
    filter "z"
}

#######################################
# Creates normal buffer image by mapping normal vectors to a rgb color.
# Globals:
#   (uses)  meta
#   (uses)  path
# Outputs:
#   saves normal.hdr image in $path folder
#######################################
function create_normal_buffer {
    echo "Generating normal buffer"
    vwrays -ff $meta/global.unf | rtrace -w -fff -on $meta/scene.oct > $meta/normal.pts
    getinfo -c rcalc -if3 -of -e '$1=($1+1)/2;$2=($2+1)/2;$3=($3+1)/2' < $meta/normal.pts | pvalue -r -df `getinfo -d < $meta/global.unf` > $meta/normal.unf
    filter "normal"
}

#######################################
# Creates indirect buffer image by subtracting local illumination from global illumination.
# Globals:
#   (uses)  meta
#   (uses)  path
# Outputs:
#   saves indirect.hdr image in $path folder
#######################################
function create_indirect_buffer {
    echo "Generating indirect buffer"
    pcomb $meta/global.unf -s -1 $meta/local.unf > $meta/indirect.unf
    filter "indirect"
} 