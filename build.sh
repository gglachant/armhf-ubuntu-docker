#!/bin/sh
#
# Build armv7l Ubuntu base image for docker (on x86 as well as armhf machines)
# - needs qemu-user-static installed
# - image will be tagged with the chosen version
#
# Synopsis: build.sh [VERSION] [IMAGE NAME]
#
# Defaults: build.sh 14.04 <YOUR-DOCKER-USER>/armhf-ubuntu

# Fail on error
set -e

VERSION=${1:-15.10}
ARCHIVE_NAME=ubuntu-core-$VERSION-core-armhf.tar
BASE_IMAGE_URL=http://cdimage.ubuntu.com/ubuntu-core/releases/$VERSION/release/${ARCHIVE_NAME}.gz
TMP_DIR=`mktemp -d`

# Check if current user is member of docker group and only use sudo if necessary
DOCKER_CMD=docker
if ! id -Gn | grep -qw 'docker'; then
  DOCKER_CMD=sudo $DOCKER_CMD
fi

# Check if running on armv7l architecture
if [ $(uname -m) = "armv7l" ]; then
  ON_ARM=1
fi

echo ARM: $ON_ARM

# Use given image name or the default one (with your username)
if [ -n "$2" ]; then
  IMAGE_NAME=$2:$VERSION
else
  DOCKER_USER=$($DOCKER_CMD info | grep Username | awk '{print $2;}')
  IMAGE_NAME=$DOCKER_USER/armhf-ubuntu:$VERSION
fi

echo Building $IMAGE_NAME

# Unzip Ubuntu core image
curl $BASE_IMAGE_URL | gunzip -c >$TMP_DIR/${ARCHIVE_NAME}

# Keep us lean by effectively running "apt-get clean" after every install
aptGetClean='"rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true";'
aptConfPath=etc/apt/apt.conf.d
mkdir -p $TMP_DIR/$aptConfPath
echo >&2 "+ cat > '$TMP_DIR/$aptConfPath/docker-clean'"
cat > "$TMP_DIR/$aptConfPath/docker-clean" <<-EOF
  DPkg::Post-Invoke { ${aptGetClean} };
  APT::Update::Post-Invoke { ${aptGetClean} };

  Dir::Cache::pkgcache "";
  Dir::Cache::srcpkgcache "";
EOF

# Remove apt-cache translations for fast "apt-get update"
echo >&2 "+ cat > '$TMP_DIR/$aptConfPath/docker-no-languages'"
echo 'Acquire::Languages "none";' > "$TMP_DIR/$aptConfPath/docker-no-languages"

# Add files to base image and import it
cd $TMP_DIR && tar rf $TMP_DIR/${ARCHIVE_NAME} -P $aptConfPath
if [ ! $ON_ARM ]; then
  tar rf $TMP_DIR/${ARCHIVE_NAME} -P /usr/bin/qemu-arm-static
fi
cat $TMP_DIR/${ARCHIVE_NAME} | $DOCKER_CMD import - $IMAGE_NAME
rm $TMP_DIR/${ARCHIVE_NAME} $TMP_DIR/$aptConfPath -fR

# Use qemu unless running on armv7l architecture
if [ ! $ON_ARM=1 -a ! -f /proc/sys/fs/binfmt_misc/arm ]; then
  sudo sh -c 'echo ":arm:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-arm-static:" >/proc/sys/fs/binfmt_misc/register'
fi

# Update packages
# FIXME Replace udev hold as soon as it does correctly upgrade on qemu
UPDATE_SCRIPT="dpkg-divert --local --rename --add /sbin/initctl && \
               ln -s /bin/true /sbin/initctl && \
               echo 'udev hold' | dpkg --set-selections && \
               sed -i -e 's/# \(.*universe\)$/\1/' /etc/apt/sources.list && \
               export DEBIAN_FRONTEND=noninteractive; apt-get update && apt-get -y upgrade"
CID=`$DOCKER_CMD run -d $IMAGE_NAME sh -c "$UPDATE_SCRIPT"`
$DOCKER_CMD attach $CID
$DOCKER_CMD commit $CID $IMAGE_NAME
$DOCKER_CMD rm $CID

echo "Successfully built image $IMAGE_NAME."
