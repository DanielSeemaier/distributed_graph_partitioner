#!/bin/bash

. "$script_pwd/../partitioners/inc/git.sh"
. "$script_pwd/../partitioners/inc/kagen-partitioner.sh"

Fetch() {
    local -n fetch_args=$1

    if (( ${fetch_args[install_disk_driver]} )); then 
        FetchDiskDriver fetch_args
    fi
    if (( ${fetch_args[install_kagen_driver]} )); then 
        FetchKaGenDriver fetch_args
    fi
}

FetchDiskDriver() {
    local -n fetch_disk_driver_args=$1

    if [[ $DKAMINPAR_USE_PUBLIC_REPOSITORY == 1 ]]; then
        GenericGitFetch fetch_disk_driver_args "git@github.com:KaHIP/KaMinPar.git" "disk_driver_src"
    else 
        GenericGitFetch fetch_disk_driver_args "git@github.com:DanielSeemaier/KaMinPar.git" "disk_driver_src"
    fi
}

FetchKaGenDriver() {
    local -n fetch_kagen_driver_args=$1

    if [[ $DKAMINPAR_USE_KAGEN_DRIVER == 1 ]]; then 
        GenericKaGenPartitionerFetch fetch_kagen_driver_args
    else
        FetchDiskDriver fetch_kagen_driver_args
    fi
}

Install() {
    local -n install_args=$1
    
    if (( ${install_args[install_disk_driver]} )); then 
        InstallDiskDriver install_args
    fi
    if (( ${install_args[install_kagen_driver]} )); then 
        InstallKaGenDriver install_args
    fi
}

InstallDiskDriver() {
    local -n install_disk_driver_args=$1

    src_dir="${install_disk_driver_args[disk_driver_src]}"

    cmake -S "$src_dir" \
        -B "$src_dir/build" \
        -DCMAKE_BUILD_TYPE=Release \
        -DKAMINPAR_BUILD_DISTRIBUTED=On \
        $CUSTOM_CMAKE_FLAGS \
        ${install_disk_driver_args[algorithm_build_options]}
    cmake --build "$src_dir/build" --target dKaMinPar --parallel

    cp "$src_dir/build/apps/dKaMinPar" "${install_disk_driver_args[disk_driver_bin]}"
}

InstallKaGenDriver() {
    local -n install_kagen_driver_args=$1

    if [[ $DKAMINPAR_USE_KAGEN_DRIVER == 1 ]]; then 
        if [[ $DKAMINPAR_USE_PUBLIC_REPOSITORY == 0 ]]; then
            GenericKaGenPartitionerInstall install_kagen_driver_args "-DBUILD_DKAMINPAR=On -DKAMINPAR_REPOSITORY=git@github.com:DanielSeemaier/KaMinPar.git" "dKaMinPar"
        else
            GenericKaGenPartitionerInstall install_kagen_driver_args "-DBUILD_DKAMINPAR=On" "dKaMinPar"
        fi
    else
        InstallDiskDriver install_kagen_driver_args
        cp "${install_kagen_driver_args[disk_driver_bin]}" "${install_kagen_driver_args[kagen_driver_bin]}"
    fi
}

InvokeFromDisk() {
    local -n invoke_from_disk_args=$1
    
    graph="${invoke_from_disk_args[graph]}"
    [[ -f "$graph.graph" ]] && graph="$graph.graph"
    [[ -f "$graph.metis" ]] && graph="$graph.metis"
    [[ -f "$graph.bgf" ]] && graph="$graph.bgf"
    [[ -f "$graph.parhip" ]] && graph="$graph.parhip"

    if [[ -f "$graph" ]]; then
        echo -n "${invoke_from_disk_args[bin]} "
        echo -n "-G $graph "
        echo -n "-k ${invoke_from_disk_args[k]} "
        echo -n "-e ${invoke_from_disk_args[epsilon]} "
        echo -n "--seed=${invoke_from_disk_args[seed]} "
        echo -n "-t ${invoke_from_disk_args[num_threads]} "
        echo -n "-T "
        echo -n "${invoke_from_disk_args[algorithm_arguments]}"
        echo ""
    else 
        >&2 echo "Warning: Graph $graph does not exist; skipping instance"
        return 1
    fi
}

InvokeFromKaGen() {
    local -n invoke_from_kagen_args=$1

    if [[ $DKAMINPAR_USE_KAGEN_DRIVER == 1 ]]; then 
        echo -n "${invoke_from_kagen_args[bin]} "
        echo -n "-s ${invoke_from_kagen_args[seed]} " 
        echo -n "-k ${invoke_from_kagen_args[k]} "
        echo -n "-t ${invoke_from_kagen_args[num_threads]} "
        echo -n "-e ${invoke_from_kagen_args[epsilon]} "
        echo -n "${invoke_from_kagen_args[algorithm_arguments]} "
        echo -n "-G\"${invoke_from_kagen_args[kagen_arguments_stringified]}\""
        echo ""
    else
        echo -n "${invoke_from_kagen_args[bin]} "
        echo -n "--seed ${invoke_from_kagen_args[seed]} " 
        echo -n "-k ${invoke_from_kagen_args[k]} "
        echo -n "-t ${invoke_from_kagen_args[num_threads]} "
        echo -n "-e ${invoke_from_kagen_args[epsilon]} "
        echo -n "-T "
        echo -n "${invoke_from_kagen_args[algorithm_arguments]} "
        echo -n "-G\"${invoke_from_kagen_args[kagen_arguments_stringified]}\""
        echo ""
    fi
}

