#!/bin/bash

set -e

if [ "$1" = "-v" ]; then
    verbosity=1
elif [ "$1" = "-vv" ]; then
    verbosity=2
elif [ "$1" = "-vvv" ]; then
    verbosity=3
else
    verbosity=0
fi

orig_project=$(oc project -q)

total_revisions=0

for project in $(oc get project -o name | cut -d "/" -f 2 ); do 
    oc project $project > /dev/null
    imagestreams_json="$(oc get is -o json)"
    is_count="$(echo "$imagestreams_json" | jq '.items | length')"

    project_revisions=0

    for j in $(seq 0 $is_count); do
        imagestream_json="$(echo "$imagestreams_json" | jq '.items['$j']')"
        imagestream="$(echo "$imagestream_json" | jq '.metadata.name' -r)"
        tag_count="$(echo "$imagestream_json" | jq '.status.tags | length' -r)"

        is_revisions=0

        for i in $(seq 0 $tag_count); do
            tag="$(echo "$imagestream_json" | jq '.status.tags['$i'].tag' -r)"
            revisions="$(echo "$imagestream_json" | jq '.status.tags['$i'].items | length' -r)"

            if (( $verbosity >= 3 )); then
                echo "$revisions $project $imagestream $tag"
            fi

            is_revisions=$(($revisions+$is_revisions))
        done

        if (( $verbosity >= 2 )); then
            echo "$is_revisions $project $imagestream total"
        fi

        project_revisions=$(($is_revisions+$project_revisions))
    done

    if (( $verbosity >= 1 )); then
        echo "$project_revisions $project total"
    fi

    total_revisions=$(($project_revisions+$total_revisions))
done

echo "$total_revisions total"

oc project $orig_project > /dev/null