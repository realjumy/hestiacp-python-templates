<VirtualHost %ip%:%web_port%>

    ServerName %domain_idn%
    %alias_string%
    ServerAdmin %email%
    DocumentRoot %docroot%
    ScriptAlias /cgi-bin/ %home%/%user%/web/%domain%/cgi-bin/
    Alias /vstats/ %home%/%user%/web/%domain%/stats/
    Alias /error/ %home%/%user%/web/%domain%/document_errors/
    #SuexecUserGroup %user% %group%
    CustomLog /var/log/%web_system%/domains/%domain%.bytes bytes
    CustomLog /var/log/%web_system%/domains/%domain%.log combined
    ErrorLog /var/log/%web_system%/domains/%domain%.error.log
    
    IncludeOptional %home%/%user%/conf/web/%domain%/apache2.forcessl.conf*

    <Directory %home%/%user%/web/%domain%/stats>
        AllowOverride All
    </Directory>

    <Directory %docroot%>
        AllowOverride All
        Options +Includes -Indexes +ExecCGI
    </Directory>

    <IfModule mod_wsgi.c>
        WSGIScriptReloading On
        WSGIScriptAlias / %docroot%/app/app.wsgi
        WSGIDaemonProcess %domain%-django user=%user% group=%user% processes=1 threads=5 display-name=%{GROUP} python-path=%docroot%/venv/lib/python3.7/site-packages
        WSGIProcessGroup %domain%-django
        WSGIApplicationGroup %{GLOBAL}
    </IfModule>

    <Directory %docroot%>
        AllowOverride FileInfo
        Options ExecCGI Indexes
        MultiviewsMatch Handlers
        Options +FollowSymLinks
        Order allow,deny
        Allow from all
    </Directory>

    IncludeOptional %home%/%user%/conf/web/%web_system%.%domain%.conf*

</VirtualHost>
