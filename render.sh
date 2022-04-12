. ./common.sh

#######################################
# Loops in parallel over each scene description file (*.rad) in a folder and creates all the buffers for it.
# Arguments:
#   $1 -> input folder
#   $2 -> output folder
#   $3 -> list of possible light positions (default: "up") -> valid values: up, down, left, right, back
#   $4 -> whether to use multiple cameras (default: no) -> one of: yes, no
#   $5 -> whether to create a caustic photon map -> either "cpm" or nothing
#   $6 -> whether to create a volume photon map -> either "vpm" or nothing
# Outputs:
#   saves .hdr images for each buffer (diffuse, local, global, normal, depth, indirect) in $2 folder
#######################################
function main {
  n=0
  N=15
  for file in $1/*.rad
  do
    if [ "$n" -eq "$N" ]; then
      wait
      n=0
    fi
    loop $file $2 "${3:-up}" ${4:-no} $5 $6 &
    n=$(( n + 1 ))
  done
  wait
}

#######################################
# Performs buffer renders for a given scene description.
# Arguments:
#   $1 -> file describing a scene to process
#   $2 -> output directory
#   $3 -> list of possible light positions -> valid values: up, down, left, right, back
#   $4 -> whether to use multiple cameras -> one of: yes, no
#   $5 -> whether to create a caustic photon map -> either "cpm" or nothing
#   $6 -> whether to create a volume photon map -> either "vpm" or nothing
# Outputs:
#   saves .hdr images for each buffer (diffuse, local, global, normal, depth, indirect) in $2 folder
#######################################
function loop {
    setup "$@"
    create_diffuse_buffer $4
    create_local_illum $4
    create_global_illum $4
    create_depth_buffer
    create_normal_buffer
    create_indirect_buffer

    # cleanup
    rm -r $meta
}

main "$@"