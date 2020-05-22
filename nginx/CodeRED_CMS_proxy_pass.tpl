server {
    listen      %ip%:%proxy_port%;
    server_name %domain_idn% %alias_idn%;
       
    include %home%/%user%/conf/web/%domain%/nginx.forcessl.conf*;

    location = /favicon.ico { access_log off; log_not_found off; }

    # Maximum file upload size.
    client_max_body_size 64M;

    # Enable content compression for text types.
    gzip on;
    gzip_types text/plain text/css application/x-javascript image/svg+xml;
    gzip_comp_level 1;
    gzip_disable msie6;
    gzip_http_version 1.0;
    gzip_proxied any;
    gzip_vary on;

    location /static/ {
        root %home%/%user%/web/%domain%/cr_cms/;
    }

    # Set a longer expiry for CACHE/, because the filenames are unique.
    location /static/CACHE/ {
        access_log off;
        expires 864000;
        alias %home%/%user%/web/%domain%/cr_cms/static/CACHE;
    }

    # Only serve /media/images/ by default, not e.g. original_images/.
    location /media/images/ {
        expires 864000;
        alias %home%/%user%/web/%domain%/cr_cms/media/images/;
    }

    location / {
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass      http://unix:/run/%domain%-gunicorn.sock;
        location ~* ^.+\.(%proxy_extentions%)$ {
            root           %home%/%user%/web/%domain%/cr_cms/;
            access_log     /var/log/%web_system%/domains/%domain%.log combined;
            access_log     /var/log/%web_system%/domains/%domain%.bytes bytes;
            expires        max;
            try_files      $uri @fallback;
        }
    }

    location /error/ {
        alias   %home%/%user%/web/%domain%/document_errors/;
    }

    location @fallback {
        proxy_pass      http://%ip%:%web_port%;
    }

    location ~ /\.ht    {return 404;}
    location ~ /\.svn/  {return 404;}
    location ~ /\.git/  {return 404;}
    location ~ /\.hg/   {return 404;}
    location ~ /\.bzr/  {return 404;}

    include %home%/%user%/conf/web/%domain%/nginx.conf_*;
}
