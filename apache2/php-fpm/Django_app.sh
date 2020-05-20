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
pip install django gunicorn

# Create the Django project
django-admin startproject djangoapp

# Django does not have a requirements.txt file
# Install requirements.txt in case one is given by the user in
# the working folder
if [ -f "$workingfolder/djangoapp/requirements.txt" ]; then

     pip install -r /home/$user/web/$domain/djangoapp/requirements.txt

fi

# Make Django migration and  change ownership of the created SQLite database
cd djangoapp
./manage.py makemigrations && ./manage.py migrate
chown $user:$user db.sqlite3

# Add static folder and run collectstatic
echo "
STATIC_ROOT = os.path.join(BASE_DIR, 'static/')" >> djangoapp/settings.py
./manage.py collectstatic

# At this stage you can test that it works executing:
# gunicorn -b 0.0.0.0:8000 djangoapp.wsgi:application
# *after* adding your domain to ALLOWED_HOSTS

# This following part adds Gunicorn socket and service,
# and needs to be improved, particularly to allow multiple
# Django applications running in the same server.

# This is intended for Ubuntu. It will require some testing to check how this works
# in other distros.

if [ ! -f "/etc/systemd/system/gunicorn.socket" ]; then

echo "[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target" > /etc/systemd/system/gunicorn.socket

fi

# In case the service exists (this needs to be improved!!!!)
# I don't know why this is executed afther the next IF when a file doesn't exit
#if [ -f "/etc/systemd/system/gunicorn.service" ]; then
#    echo "[Service]
#User=$user
#Group=$user
#WorkingDirectory=$workingfolder/djangoapp
#ExecStart=$workingfoler/venv/bin/gunicorn --access-logfile - --workers 3 --bind unix:/run/gunicorn.sock djangoapp.wsgi:application
#
#[Install]
#WantedBy=multi-user.target" >> /etc/systemd/system/gunicorn.service
#
#fi

# If the service doesn't exist
if [ ! -f "/etc/systemd/system/gunicorn.service" ]; then

    echo "[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=$user
Group=$user
WorkingDirectory=$workingfolder/djangoapp

ExecStart=$workingfolder/venv/bin/gunicorn --access-logfile - --workers 3 --bind unix:/run/gunicorn.sock djangoapp.wsgi:application

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/gunicorn.service

fi

systemctl restart gunicorn.socket

systemctl start gunicorn.socket

systemctl enable gunicorn.socket

# Start the socket
curl --unix-socket /run/gunicorn.sock localhost

sudo systemctl daemon-reload

sudo systemctl restart gunicorn

exit 0
