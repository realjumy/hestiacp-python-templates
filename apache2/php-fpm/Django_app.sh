#!/bin/bash
# Adding php wrapper
user="$1"
domain="$2"
ip="$3"
home_dir="$4"
docroot="$5"

cd $home_dir $docroot/
virtualenv -p python3 venv
source venv/bin/activate

pip install django
pip install gunicorn

if [ -f $docroot/djangoapp/app.wsgi ]; then
	pip install -r $docroot/requirements.txt
fi

django-admin startproject djangoapp $docroot
cd $docroot/djangoapp

gunicorn wsgi.py

./manage.py makemigrations && ./manage.py migrate
chown $user:$user db.sqlite3

if [ ! -f /etc/systemd/system/gunicorn.socket]; then
cat >/etc/systemd/system/gunicorn.socket <<EOL
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target

EOL

fi

if [ ! -f /etc/systemd/system/gunicorn.service]; then

cat >/etc/systemd/system/gunicorn.service <<EOL

[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=${user}
Group=${user}
WorkingDirectory=${docroot}/djangoapp
ExecStart=${docroot}/venv/bin/gunicorn \
          --access-logfile - \
          --workers 3 \
          --bind unix:/run/gunicorn.sock \
          djangoapp.wsgi:application

[Install]
WantedBy=multi-user.target


EOL
	
fi


if [ -f /etc/systemd/system/gunicorn.service]; then
cat >>/etc/systemd/system/gunicorn.service <<EOL

[Service]
User=${user}
Group=${user}
WorkingDirectory=${docroot}/djangoapp
ExecStart=${docroot}/venv/bin/gunicorn \
          --access-logfile - \
          --workers 3 \
          --bind unix:/run/gunicorn.sock \
          djangoapp.wsgi:application

[Install]
WantedBy=multi-user.target

EOL

fi

systemctl restart gunicorn.socket
systemctl start gunicorn.socket
systemctl enable gunicorn.socket

curl --unix-socket /run/gunicorn.sock localhost

sudo systemctl daemon-reload
sudo systemctl restart gunicorn


deactivate

if [ ! -f $docroot/.htaccess ]; then
echo "RewriteEngine On

RewriteCond %{HTTP_HOST} ^www.$2\.ru\$ [NC]
RewriteRule ^(.*)\$ http://$2/\$1 [R=301,L]

RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^(.*)\$ /djangoapp/app.wsgi/\$1 [QSA,PT,L]" > $docroot/.htaccess
chown $user:$user $docroot/.htaccess
fi


echo "Remember to complete the app setup process! Also, check the content of the file etc/systemd/system/gunicorn.service" > $docroot/help

exit 0
