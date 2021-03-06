#!/bin/sh
#########################################

owncloud_pbi_path=/usr/pbi/owncloud-$(uname -m)

${owncloud_pbi_path}/bin/python2.7 ${owncloud_pbi_path}/owncloudUI/manage.py syncdb --migrate --noinput

# Restore ownCloud config otherwise set /media as the ownCloud data-directory
if [ -f "/media/config.php" ]; then
	mv /media/config.php ${owncloud_pbi_path}/www/owncloud/config
else
	cat << __EOF__ > ${owncloud_pbi_path}/www/owncloud/config/autoconfig.php
<?php
\$AUTOCONFIG = array (
  "dbtype" => "sqlite",
  "directory" => "/media",
);
?>
__EOF__
fi

# Create cronjob for ownCloud
tmp=$(mktemp /tmp/tmp.XXXXXX)
echo "*/15 * * * * ${owncloud_pbi_path}/bin/php -f ${owncloud_pbi_path}/www/owncloud/cron.php" > ${tmp}
crontab -u www ${tmp}

# Create Apache alias for ownCloud
cat << __EOF__ > ${owncloud_pbi_path}/etc/apache24/Includes/owncloud.conf
AddType application/x-httpd-php .php

Alias / ${owncloud_pbi_path}/www/owncloud/
<Directory ${owncloud_pbi_path}/www/owncloud>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    SetEnv MOD_X_SENDFILE_ENABLED 1
    XSendFile On
    XSendFilePath /media
</Directory>
__EOF__

# Allow ownCloud updater to work
chown -R www:www ${owncloud_pbi_path}/www/owncloud /media


# Generate SSL certificate
if [ ! -f "${owncloud_pbi_path}/etc/apache24/server.crt" ]; then

	if ! grep -e '^commonName_default[[:space:]]*=' /etc/ssl/openssl.cnf; then
		sed -i '' -e '/^commonName_max[[:space:]]*=/ a\
commonName_default = ownCloud\
' /etc/ssl/openssl.cnf
	fi
	dd if=/dev/urandom count=16 bs=1 2> /dev/null | uuencode -|head -2 |tail -1 > "${tmp}"
	openssl req -batch -passout file:"${tmp}" -new -x509 -keyout ${owncloud_pbi_path}/etc/apache24/server.key.out -out ${owncloud_pbi_path}/etc/apache24/server.crt
	openssl rsa -passin file:"${tmp}" -in ${owncloud_pbi_path}/etc/apache24/server.key.out -out ${owncloud_pbi_path}/etc/apache24/server.key

fi

# Enable SSL
sed -i '' -e 's|^#\(Include[[:space:]].*/httpd-ssl.conf$\)|\1|' ${owncloud_pbi_path}/etc/apache24/httpd.conf
sed -i '' -e 's/^#\(LoadModule[[:space:]]*ssl_module[[:space:]].*$\)/\1/' ${owncloud_pbi_path}/etc/apache24/httpd.conf
sed -i '' -e 's/^#\(LoadModule[[:space:]]*socache_shmcb_module[[:space:]].*$\)/\1/' ${owncloud_pbi_path}/etc/apache24/httpd.conf

# Optimize Apache on ZFS
sed -i '' -e 's/^#\(EnableMMAP[[:space:]]\).*$/\1Off/' ${owncloud_pbi_path}/etc/apache24/httpd.conf

# Add paths to Apache
if [ ! -f "${owncloud_pbi_path}/etc/apache24/envvars.d/path.env" ]; then
cat << __EOF__ > ${owncloud_pbi_path}/etc/apache24/envvars.d/path.env
export PATH=${owncloud_pbi_path}/bin:/usr/local/bin:\$PATH
export LD_LIBRARY_PATH=/usr/local/lib:\$LD_LIBRARY_PATH
__EOF__
fi

# Enable X-Sendfile
sed -i '' -e 's/^#\(LoadModule[[:space:]]*xsendfile_module[[:space:]].*$\)/\1/' ${owncloud_pbi_path}/etc/apache24/httpd.conf

# Set charset for PHP
if [ ! -f "${owncloud_pbi_path}/etc/php.ini" ]; then
	echo 'default_charset = "UTF-8"' > ${owncloud_pbi_path}/etc/php.ini
fi
