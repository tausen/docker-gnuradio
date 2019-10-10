# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image

# set noninteractive installation
export DEBIAN_FRONTEND=noninteractive
# install tzdata package
apt-get update
apt-get install -y tzdata
# set your timezone
ln -fs /usr/share/zoneinfo/Europe/Copenhagen /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata
