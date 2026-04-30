# Pull from image registry

New image versions may not be immediately available in the object storage. To use these new versions in SD Desktop, you have to pull them from an image registry.

Find out available versions: https://github.com/chipster/chipster-openshift/blob/k3s/k3s/README.md#select-chipster-version .

The following script is provided as an example how to pull those images:
https://github.com/chipster/chipster-openshift/blob/master/podman/disconnected/prepare/pull-images.bash . It uses the repository `chipster-openshift` to find all image names. Change the path in the script if you have checked out the repository somewhere else.
