# Pi-hole Android Private DNS Docker Installer 

<img src="https://raw.githubusercontent.com/sreejithag/pi-hole-android-private-dns-docker/main/assets/banner.png"> <br/>

I have been using pi-hole for a while now by deploying it on a cloud VM instance. It has been working well for all devices in my home network as I set the my router to use pi-hole as the DNS server but their was an issue as Android phones don't allow to use cutom DNS on mobile data by giving the IP address of the DNS server.

From Android version 9 and above we can use private DNS but it is DNS over TLS and pi-hole officially not support it till now. While searching for a solution I found this awesome project [pi-hole-android-private-dns](https://github.com/varunsridharan/pi-hole-android-private-dns)


`./setup.sh <your-domain-name> <email> <time zone> <password>`
