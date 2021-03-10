# Pi-hole Android Private DNS Docker Installer 

<img src="https://raw.githubusercontent.com/sreejithag/pi-hole-android-private-dns-docker/main/assets/banner.png"> <br/>

I have been using pi-hole for a while now by deploying it on a cloud VM instance. It has been working well for all devices in my home network as I set my router to use pi-hole as the DNS server but there was an issue as Android phones don't allow to use of custom DNS on mobile data by giving the IP address of the DNS server.

From Android version 9 and above we can use private DNS but it is DNS over TLS and pi-hole officially not support it till now. While searching for a solution I found this awesome project [pi-hole-android-private-dns](https://github.com/varunsridharan/pi-hole-android-private-dns) it worked well, the issue with it was it requires pi-hole to be installed separately and it installs Nginx directly to the server and I wanted everything to be run with docker and an easy one-step solution.

This script will install and configure pi-hole with DNS over TLS using Docker. 

## Requirements 

1. Ubuntu / any Linux distributtion
2. Docker and Docker compose installed (Installation guide of [Docker](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04) and [Docker-Compose](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-20-04) for ubuntu 20.04)
3. Domain pointing to public IP address of the server
4. Allow following TCP ports (`80,443,853,53`) and UDP ports (`53,67`) [Ubuntu users refer Notes](README.md#notes)

## Installation

Script requires 4 arguments 

1. Domain which points to public IP address of the server 
2. Email for letsencrypt to get an SSL certificate for the domain
3. Time zone for the pi-hole server (Refer the [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)) 
4. Password for the pi-hole server which can be used to login to the web UI

### Steps
```
1. wget https://bit.ly/pihole-android
2. bash setup.sh <your_domain> <email> <time zone> <password>
```
**Example** `bash setup.sh pihole.yourdomain.com youremail@gmail.com Asia/Kolkata password123`


## Notes
### Installing on Ubuntu

Modern releases of Ubuntu (17.10+) include systemd-resolved which is configured by default to implement a caching DNS stub resolver. This will prevent pi-hole from listening on port 53. if you wnat the pihole to run only on DNS over TLS please remove line number 42,43 and 44 of setup.sh file. If you need pihole to work like normal DNS server with its IP address, disable the systemd-resolved by following the setps.

1. `sudo systemctl stop systemd-resolved.service`
2. `sudo systemctl disable systemd-resolved.service `
3. Edit `/etc/resolv.conf` file and change Nameserver from 127.0.0.1 to known DNS like 8.8.8.8 or 1.1.1.1

### Docker Installation
Add the current user to the docker group so that user could run docker commands without the need of sudo previlages if not able to add user to the docker group please edit the setup.sh file and add sudo before every docker-compose and docker commands.

### Disclaimer
I have not Raspberry to test it. used Ubuntu 20.04 for testing this and have not used any other Linux distributions for the testing but the script should work fine if docker and docker-compose are installed correctly on the system.

