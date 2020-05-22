#!/bin/bash
# Adding php wrapper
user="$1"
domain="$2"
ip="$3"
#/home
home_dir="$4"
#Full route to /public_html
docroot="$5"


workingfolder="/home/$user/web/$domain"

cd $workingfolder

# Create the virtual environment with Python 3
virtualenv -p python3 venv

# Activate the virtual environment
source venv/bin/activate

# Install Django and Gunicorn
pip install coderedcms gunicorn psycopg2-binary

# Create the Django project
coderedcms start cr_cms

# Install requirements.txt in case one is available
# the working folder
if [ -f "$workingfolder/cr_cms/requirements.txt" ]; then

     pip install -r /home/$user/web/$domain/cr_cms/requirements.txt

fi

# Make Django migration and  change ownership of the created SQLite database
cd cr_cms
python manage.py makemigrations && python manage.py migrate
chown $user:$user db.sqlite3

# Add static and media folder and run collectstatic
mkdir static
chmod 755 static
chown $user:$user static
mkdir static/CACHE
chmod 755 static/CACHE
chown $user:$user static/CACHE
mkdir media
chmod 755 media
chown $user:$user media
python manage.py collectstatic

# At this stage you can test that it works executing:
# gunicorn -b 0.0.0.0:8000 cr_cms.wsgi:application
# *after* adding your domain to ALLOWED_HOSTS

# This following part adds Gunicorn socket and service,
# and needs to be improved, particularly to allow multiple
# Django applications running in the same server.

# This is intended for Ubuntu. It will require some testing to check how this works
# in other distros.

if [ ! -f "/etc/systemd/system/$domain-gunicorn.socket" ]; then

echo "[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/$domain-gunicorn.sock

[Install]
WantedBy=sockets.target" > /etc/systemd/system/$domain-gunicorn.socket

fi

if [ ! -f "/etc/systemd/system/$domain-gunicorn.service" ]; then

    echo "[Unit]
Description=Gunicorn daemon for $domain
Requires=$domain-gunicorn.socket
After=network.target

[Service]
User=$user
Group=$user
WorkingDirectory=$workingfolder/cr_cms

ExecStart=$workingfolder/venv/bin/gunicorn --access-logfile - --workers 3 --bind unix:/run/$domain-gunicorn.sock -m 007 cr_cms.wsgi:application

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/$domain-gunicorn.service

fi


systemctl enable $domain-gunicorn.socket

systemctl start $domain-gunicorn.socket


# Start the socket
curl --unix-socket /run/$domain-gunicorn.sock localhost

sudo systemctl daemon-reload

sudo systemctl restart $domain-gunicorn

exit 0
