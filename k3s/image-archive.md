# Chipster image archive

[Update instructions](README.md#updates) show how to use latest image versions in our image registry. Only a few latest image versions are kept available in the live image registry, where from K3s can pull images directly when necessary. The older image versions are available in an object storage. Instructions on this page show how download and import these older image versions to K3s.

## List image versions

Use the following command to list available image version in the object storage. The output could look something like this:

```bash
$ curl -s https://a3s.fi/swift/v1/AUTH_chipcld/chipster-images/ | sort --version-sor
t
chipster-images-v4.9.12.tar.lz4
chipster-images-v4.10.3.tar.lz4
chipster-images-v4.13.4.tar.lz4
chipster-images-v4.13.10.tar.lz4
```

## Download images

Here are example commands that you can use to download, extract and import your chosen version (v4.13.10 in this example).

```bash
# create a temporary directory
mkdir /mnt/data/image-download-temp
sudo chown $(whoami) /mnt/data/image-download-temp
cd /mnt/data/image-download-temp

# download and extract an image package
curl https://a3s.fi/chipster-images/chipster-images-v4.13.10.tar.lz4 | lz4 -d | tar -x

# import images to K3s
for img in *.tar; do
  sudo k3s ctr image import $img
done

# remove the temporary directory
rm -rf /mnt/data/image-download-temp
```

These steps will replace the parts of the primary [update instructions](README.md#updates), where you choose the image version and pull the images. You still have to follow other steps there, including the configuration of the image version in `~/values.yaml` and deploying with `bash deploy.bash -f ~/values.yaml`.
