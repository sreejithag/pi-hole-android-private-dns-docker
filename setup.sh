echo "========================================================="
echo "==!! Pihole Android Private DNS With Docker !!=="
echo "========================================================="
echo ""

domain_name="$1"
email="$2"
tz="$3"
passwd="$4"

if [ -z "$domain_name" ]; then
  echo "🛑 Provide a doamin name"
  exit 1
fi

if [ -z "$email" ]; then
  echo "🛑 Provide an email address for lets encrypt"
  exit 1
fi



if [ -z "$tz" ]; then
  echo "🛑 Provide a timezone"
  exit 1
fi


if [ -z "$passwd" ]; then
  echo "🛑 Provide a password"
  exit 1
fi

touch docker-compose.yml

echo "version: '3'

services:
  pihole:
    image: pihole/pihole:latest
    ports:
      - \"53:53/tcp\"
      - \"53:53/udp\"
      - \"67:67/udp\"
    volumes:
     - './etc-pihole/:/etc/pihole/'
     - './etc-dnsmasq.d/:/etc/dnsmasq.d/'
    environment:
      TZ: '$tz'
      WEBPASSWORD: '$passwd'
      VIRTUAL_HOST: '$domain_name'
    networks:
     - app-network
    restart: unless-stopped
  webserver:
    image: nginx:mainline-alpine
    container_name: webserver
    restart: unless-stopped
    ports:
      - \"80:80\"
      - \"443:443\"
      - \"853:853\"
    volumes:
      - ./web-root:/var/www/html
      - ./nginx-conf:/etc/nginx/conf.d
      - ./certbot-etc:/etc/letsencrypt
      - ./certbot-var:/var/lib/letsencrypt
    depends_on:
      - pihole
    networks:
      - app-network
    
  certbot:
    image: certbot/certbot
    container_name: certbot
    volumes:
      - ./certbot-etc:/etc/letsencrypt
      - ./certbot-var:/var/lib/letsencrypt
      - ./web-root:/var/www/html
    depends_on:
      - webserver
    command: certonly --webroot --webroot-path=/var/www/html  --email $email --agree-tos --no-eff-email -d $domain_name 

volumes:
  etc-pihole:
  nginx-conf:
  etc-dnsmasq.d:
  certbot-etc:
  certbot-var:
  web-root:

networks:
  app-network:
    driver: bridge" > docker-compose.yml

echo ""
echo "========================================================================================"
echo "Docker-compose file Created `tput setaf 2`✓ `tput setaf 7`"
echo "========================================================================================"
echo ""

mkdir nginx-conf
mkdir nginx-conf/stream

touch nginx-conf/1.conf
touch nginx-conf/stream/2.conf


echo "server {
        listen 80;
        listen [::]:80;

        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;

        server_name $domain_name;

        
        location ~ /.well-known/acme-challenge {
                allow all;
                root /var/www/html;
        }
	
	location / {
                #proxy_pass http://pihole;
                return 301 https://\$host\$request_uri;
        }
}" > ./nginx-conf/1.conf


echo "upstream dns-servers {
           server    pihole:53;
    }

upstream pihole {
           server    pihole:80;
    }

server {
      listen 853 ssl; # managed by Certbot
      ssl_certificate /etc/letsencrypt/live/$domain_name/fullchain.pem; # managed by Certbot
      ssl_certificate_key /etc/letsencrypt/live/$domain_name/privkey.pem; # managed by Certbot
      ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
      ssl_protocols        TLSv1.2 TLSv1.3;
      ssl_ciphers          HIGH:!aNULL:!MD5;
      #ssl_handshake_timeout    10s;
      ssl_session_cache        shared:SSL:20m;
      ssl_session_timeout      4h;
      proxy_pass dns-servers;
    }

server {
      listen 443 ssl; # managed by Certbot
      ssl_certificate /etc/letsencrypt/live/$domain_name/fullchain.pem; # managed by Certbot
      ssl_certificate_key /etc/letsencrypt/live/$domain_name/privkey.pem; # managed by Certbot
      ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
      ssl_protocols        TLSv1.2 TLSv1.3;
      ssl_ciphers          HIGH:!aNULL:!MD5;
      #ssl_handshake_timeout    10s;
      ssl_session_cache        shared:SSL:20m;
      ssl_session_timeout      4h;
      proxy_pass pihole;
    }
" > ./nginx-conf/stream/2.conf

echo ""
echo "==================================================================================="
echo "Nginx Configuartion created `tput setaf 2` ✓ `tput setaf 7`"
echo "==================================================================================="
echo ""

mkdir certbot-etc

echo ""
echo "==================================================================================="
echo "genarating dhparam you might be prompted to enter the password  " 
echo ""

sudo openssl dhparam -out ./certbot-etc/ssl-dhparams.pem 204

echo ""
echo "Genarated dhparams `tput setaf 2` ✓ `tput setaf 7`"
echo ""
echo "==================================================================================="

docker-compose up -d

echo ""
echo "===================================================================================="
echo "Docker containers started `tput setaf 2` ✓ `tput setaf 7`"
echo "===================================================================================="
echo ""

echo "
    echo \"
    stream {
            include /etc/nginx/conf.d/stream/*;
    }\" >>/etc/nginx/nginx.conf
    " > setup-in-container.sh

echo ""
echo "====================================================================================="
echo "Additional Nginx configuration created `tput setaf 2` ✓ `tput setaf 7`"
echo "====================================================================================="
echo ""

docker cp setup-in-container.sh webserver:/tmp 

docker exec webserver sh /tmp/setup-in-container.sh

echo ""
echo "======================================================================================"
echo "Nginx configuartion updated `tput setaf 2` ✓ `tput setaf 7`"
echo "======================================================================================"
echo ""

echo ""
echo "======================================================================================"
echo "Checking if Certbot Finished genrating certificates if it get stuck here for long "
echo "Certbot might have failed. stop the script and check logs by running "
echo "'docker logs certbot'"
echo ""

test=`sudo ls ./certbot-etc/live/ 2> /dev/null | grep $domain_name | wc -l`

while [ "$test" != "1" ]
do
	echo -ne "...."
	sleep 2s
	test=`sudo ls ./certbot-etc/live/ 2> /dev/null | grep $domain_name | wc -l`
done

echo -ne "Certificate genarated `tput setaf 2`  ✓ `tput setaf 7`"
echo ""
echo "======================================================================================"
echo ""


docker exec webserver nginx -s reload

echo ""
echo "======================================================================================"
echo "Restarted Nginx `tput setaf 2`✓ `tput setaf 7`"
echo "======================================================================================"
echo ""

docker exec webserver rm /tmp/setup-in-container.sh
rm setup-in-container.sh

echo ""
echo "======================================================================================"
echo "Cleanup Jobs done `tput setaf 2` ✓ `tput setaf 7`"
echo "======================================================================================"
echo ""


echo "
#!/bin/bash
COMPOSE=\"/usr/local/bin/docker-compose --no-ansi\"
DOCKER=\"/usr/bin/docker\"

cd `pwd`
\$COMPOSE run certbot renew --dry-run && \$COMPOSE kill -s SIGHUP webserver
\$DOCKER system prune -af
"> ssl_renew.sh

chmod +x ssl_renew.sh

echo ""
echo "======================================================================================"
echo "Renew Script created `tput setaf 2` ✓ `tput setaf 7`"
echo ""
echo "Add  ssl_renew.sh to crontab to run every month to keep certificate renewed automatically"
echo ""
echo "Add the following line to the crontab file after running 'sudo crontab -e' to check and renew certificate very 10th day of month"
echo ""
echo " 0 0 */10 * * `pwd`/ssl_renew.sh >> /var/log/cron.log 2>&1"
echo "======================================================================================"
echo ""

echo ""
echo ""
echo ""
echo "======================================================================================"
echo "Congrats Pihole Android Private DNS with Docker is configured."
echo ""
echo "Private DNS Domain : $domain_name"
echo ""
echo "Access the admin page of pihole at : https//$domain_name/admin"
echo ""
echo "Webui Password : $passwd"
echo ""
echo "Now you can use the domain name in your android phone"
echo "======================================================================================"
