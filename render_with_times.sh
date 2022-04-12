. ./common.sh

#######################################
# Loops over each scene description file (*.rad) in a folder and creates all the buffers for it.
# Globals:
#   (modifies) total_pre
#   (modifies) total_diffuse
#   (modifies) total_local
#   (modifies) total_global
#   (modifies) total_normal
#   (modifies) total_depth
#   (modifies) total_indirect
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
  total_pre=0
  total_diffuse=0
  total_local=0
  total_global=0
  total_normal=0
  total_depth=0
  total_indirect=0

  for file in $1/*.rad
  do
    loop $file $2 "${3:-up}" ${4:-no} $5 $6
  done
  echo $total_pre $total_diffuse $total_local $total_global $total_normal $total_depth $total_indirect
}

#######################################
# Performs buffer renders for a given scene description.
# Globals:
#   (modifies) total_pre
#   (modifies) total_diffuse
#   (modifies) total_local
#   (modifies) total_global
#   (modifies) total_normal
#   (modifies) total_depth
#   (modifies) total_indirect
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
    timeit setup "$@"
    total_pre=$((total_pre + elapsed))

    timeit create_diffuse_buffer $4
    total_diffuse=$((total_diffuse + elapsed))

    timeit create_local_illum $4
    total_local=$((total_local + elapsed))

    timeit create_global_illum $4
    total_global=$((total_global + elapsed))

    timeit create_depth_buffer
    total_depth=$((total_depth + elapsed))

    timeit create_normal_buffer
    total_normal=$((total_normal + elapsed))

    timeit create_indirect_buffer
    total_indirect=$((total_indirect + elapsed))

    # cleanup
    rm -r $meta
}

main "$@"