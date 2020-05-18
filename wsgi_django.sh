#!/bin/bash
# Adding php wrapper
user="$1"
domain="$2"
ip="$3"
home_dir="$4"
docroot="$5"

cd $home_dir/$user/web/$domain/private/

virtualenv -p python3 venv
source venv/bin/activate

pip install django
# The requirements.txt file should be located at public_html/requirements.txt

if [ -f $docroot/requirements.txt ]; then
pip install -r $docroot/requirements.txt 
fi

django-admin startproject app $docroot
cd $docroot/
python manage.py startapp samplepage

deactivate

if [ ! -f $docroot/app/app.wsgi ]; then
echo "import sys
import os

sys.path.insert(0, '$docroot/app')
sys.path.insert(0, '$home_dir/$user/web/$domain/private/venv/lib/python3.6/site-packages')

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'app.settings')

application = get_wsgi_application()" > $docroot/app/app.wsgi
chown $user:$user $docroot/app/app.wsgi
fi

if [ ! -f $docroot/.htaccess ]; then
echo "RewriteEngine On

RewriteCond %{HTTP_HOST} ^www.$2\.ru\$ [NC]
RewriteRule ^(.*)\$ http://$2/\$1 [R=301,L]

RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^(.*)\$ /app/app.wsgi/\$1 [QSA,PT,L]" > $docroot/.htaccess
chown $user:$user $docroot/.htaccess
fi

echo "touch $docroot/app/app.wsgi" > $docroot/touch.sh
chown $user:$user $docroot/touch.sh
chmod +x $docroot/touch.sh

echo "For installing requirements packs:
cd $home_dir/$user/web/$domain/private/; source venv/bin/activate; pip install -r $docroot/requirements.txt; deactivate

For reloading the app:
touch $docroot/app/app.wsgi" > $docroot/help

exit 0
