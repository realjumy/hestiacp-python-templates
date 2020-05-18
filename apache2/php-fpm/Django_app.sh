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

if [ ! -f /etc/systemd/system/gunicorn.socket]; then
	# Download the file
fi

if [ ! -f /etc/systemd/system/gunicorn.service]; then
	# Download the file
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


echo "Remember to complete the app setup process!" > $docroot/help

exit 0
