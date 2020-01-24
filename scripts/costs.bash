#!/bin/bash

set -e

core_hour="0.5"
ram_gb_hour="1"
storage_tb_hour="3"
bu_eur=$(echo "scale=3; 420 / 20000" | bc -l)
hours=$((24 * 365))

echo "Using prices:"
echo "Pod core hour:          $core_hour"
echo "Pod RAM GB hour:        $ram_gb_hour"
echo "Storage TiB hour:       $core_hour"
echo "1 BU:                   $bu_eur €"
echo "Calculating prices for: $hours hours"
echo ""

function print_row () {
    type="$1"
    name="$2"
    cpu="$3"
    memory="$4"
    storage="$5"

    printf "%-20s %-30s " "$type" "$name"

    bu="0"

    if [ -n "$cpu" ]; then
        bu=$(echo "$cpu / 1000 * $core_hour + $memory / 1000 * $ram_gb_hour" | bc -l)        
    fi

    if [ -n "$storage" ]; then
        bu=$(echo "$bu + $storage / 1000000 * $storage_tb_hour" | bc -l)        
    fi

    if [ -n "$cpu" ] || [ -n "$storage" ]; then
        round_bu=$(echo "scale=2; $bu/1" | bc)
        eur=$(echo "$bu * $bu_eur * $hours" | bc -l)
        round_eur=$(echo "$eur/1" | bc)
        printf "%-10s %-10s %-10s %-10s %-10s" "$cpu" "$memory" "$storage" "$round_bu" "$round_eur"
    fi

    printf "\n"
}

projects=$(oc get project -o json | jq '.items[].metadata.name' -r)

total_cpu=0
total_memory=0
total_storage=0

printf "%-20s %-30s %-10s %-10s %-10s %-10s %-10s\n" TYPE NAME millicores "RAM MiB" "PVC MiB" BU €

for project in $(echo "$projects"); do

    project_cpu=0
    project_memory=0
    project_storage=0
    pods=$(oc -n $project get pod -o json)
    while read -r pod_index; do
        # while runs once even with empty array
        if [ -n "$pod_index" ]; then
            pod_cpu=0
            pod_memory=0
            pod=$(echo $pods | jq .items[$pod_index])
            phase=$(echo $pod | jq .status.phase -r)
            if [ $phase = "Running" ]; then
                pod_name=$(echo $pod | jq .metadata.name -r)
                
                while read  -r container_index; do
                    # while runs once even with empty array
                    if [ -n "$container_index" ]; then
                        container=$(echo $pod | jq .spec.containers[$container_index])
                        container_name=$(echo $container | jq .name -r)
                        cpu=$(echo $container | jq .resources.requests.cpu -r)
                        memory=$(echo $container | jq .resources.requests.memory -r)
                        # convert cores to millicores (and keep millicores as it is)
                        cpu=$(echo $cpu | sed "s/$/000/g" | sed "s/m000//g")
                        # convert gibibytes to mebibytes
                        memory=$(echo $memory | sed "s/Gi/000Mi/g" | sed "s/Mi//g")

                        print_row "      container" $container_name $cpu $memory

                        pod_cpu=$(($pod_cpu + $cpu))
                        pod_memory=$(($pod_memory + $memory))
                    fi
                done <<< "$(echo $pod | jq '.spec.containers | keys | .[]' -r)"

                print_row "    pod total" $pod_name $pod_cpu $pod_memory

                project_cpu=$(($project_cpu + $pod_cpu))
                project_memory=$(($project_memory + $pod_memory))
            fi
        fi
    done <<< "$(echo $pods | jq '.items | keys | .[]' -r)"

    pvcs=$(oc -n $project get pvc -o json)
    while read -r pvc_index; do
        # while runs once even with empty array
        if [ -n "$pvc_index" ]; then
            pvc=$(echo $pvcs | jq .items[$pvc_index])
            pvc_name=$(echo $pvc | jq .metadata.name -r)
            storage=$(echo $pvc | jq .spec.resources.requests.storage -r)
            # convert mebibytes
            storage=$(echo $storage | sed "s/Ti/000Gi/g" | sed "s/Gi/000Mi/g" | sed "s/Mi//g")
                    
            print_row "    pvc" $pvc_name "" "" $storage

            project_storage=$(($project_storage + $storage))
        fi
    done <<< "$(echo $pvcs | jq '.items | keys | .[]' -r)"

    print_row "  project total" $project $project_cpu $project_memory $project_storage

    total_cpu=$(($total_cpu + $project_cpu))
    total_memory=$(($total_memory + $project_memory))
    total_storage=$(($total_storage + $project_storage))
done

print_row "total" "" $total_cpu $total_memory $total_storage