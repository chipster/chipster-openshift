#!/usr/bin/env python3

import os
import yaml
import sys

def get_needs(buildconfig, build_name, builds):
    base_image = buildconfig["spec"]["strategy"]["dockerStrategy"]["from"]["name"]

    base_image_name, base_image_tag = base_image.split(":", 1)

    needs = []

    if base_image_tag == "latest":
        needs.append(base_image_name)
    else:
        print("build '" + build_name + "' has base imamge tag '" + base_image_tag + "'. Assuming this is an external image")

    source = buildconfig["spec"]["source"]

    if "images" in source:
        source_images = source["images"]

        for source_image_dict in source_images:
            image_from = source_image_dict["from"]["name"]

            source_image_name, source_image_tag = image_from.split(":", 1)

            if source_image_tag == "latest":
                needs.append(source_image_name)
            else:
                print("build '" + build_name + "' has source image tag '" + source_image_tag + "'. Assuming this is an external image")

    # remove duplicates and add only builds in this stage
    needs = list(set(needs) & set(builds))

    # add "build-" in front of each element
    return ["build-" + element for element in needs]


def check_filter(build_name, filter_str, filter_type):
    filter_passed = filter_type is build_name.startswith(filter_str)

    return filter_passed

def get_gitlab_ci(path, builds, stage):

    gitlab_ci = {}
    
    for build_dir in builds:

        with open(path + "//" + build_dir + "//" + build_dir + ".yaml", "r") as buildconfig_file:
            buildconfig = yaml.safe_load(buildconfig_file)

            needs = get_needs(buildconfig, build_dir, builds)
            
            # sort needs to avoid churn in version control
            needs.sort()

            gitlab_ci["build-" + build_dir] = {
                "stage": stage,
                "needs": needs,
                "script": [
                    "cd gitlab/pipelines/build", "bash build-image-ci.bash " + build_dir + " $CI_PIPELINE_CREATED_AT $CI_COMMIT_BRANCH"
                ]
            }
    return gitlab_ci

def write_gitlab_ci(path, builds, output_path, stage):
    gitlab_ci = get_gitlab_ci(path, builds, stage)

    header = """
# Chipster CI/CD configuration
# 
# Changes in this file will be overwritten! Make changes in BuildConfigs under kustomize/builds and run
# 
# cd generate-gitlab-ci
# python3 -m venv venv
# source venv/bin/activate
# pip3 install -r requirements.txt
# ./generate-gitlab-ci.py
# 

"""

    with open(output_path, 'w') as file:
        file.write(header)
        yaml.dump(gitlab_ci, file)

    # print(header)
    # print(yaml.dump(gitlab_ci))
    

def main() -> int:

    path = "..//..//..//..//kustomize//builds"
    dir_list = os.listdir(path)

    base_builds = []
    primary_builds = []
    comp_builds = []

    # maybe we should use directories to separate these?
    for build_dir in dir_list:

        if not os.path.isdir(path + "//" + build_dir):
            continue

        if build_dir.startswith("base"):
            base_builds.append(build_dir)
        elif build_dir.startswith("comp"):
            comp_builds.append(build_dir)
        else:
            primary_builds.append(build_dir)


    # create separate file for base builds to make it easier to skip them
    write_gitlab_ci(path, base_builds, "..//gitlab-ci-build-base.yml", "build-base")
    write_gitlab_ci(path, primary_builds, "..//gitlab-ci-build.yml", "build")
    write_gitlab_ci(path, comp_builds, "..//gitlab-ci-build-comp.yml", "build-comp")

    return 0

if __name__ == '__main__':
    sys.exit(main())




                    