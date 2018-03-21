all: packages drupalconfig createdb create-backup importdb importfiles build clean tugboat-build tugboat-init tugboat-update check-env
.PHONY: all

export COMPOSER_NO_INTERACTION = 1
export PANTHEON_PHP_VERSION = 7.2

include .tugboat/Makefile

packages: check-env install-php-${PANTHEON_PHP_VERSION} install-drush install-nodejs-8 install-terminus
#	Point /var/www/html to the web root of this site. In this case, it's the
#	root of the repo, but you could have the web root in a subdir.
	ln -sf ${TUGBOAT_ROOT} /var/www/html
#	Authenticate to terminus
	terminus auth:login --machine-token=${PANTHEON_MACHINE_TOKEN}

drupalconfig:
#	Copy the settings.local.php that works for Tugboat into sites/default.
	cp ${TUGBOAT_ROOT}/.tugboat/dist/settings.local.php ${TUGBOAT_ROOT}/sites/default/settings.local.php
#	Generate a hash_salt to secure the site.
	echo "\$$settings['hash_salt'] = '$$(openssl rand -hex 32)';" >> ${TUGBOAT_ROOT}/sites/default/settings.local.php

create-backup: check-env
	terminus backup:create ${PANTHEON_SOURCE_SITE}.${PANTHEON_SOURCE_ENVIRONMENT}

createdb:
	mysql -h mysql -u tugboat -ptugboat -e "create database drupal8;"

importdb: check-env create-backup
	terminus backup:get \
		${PANTHEON_SOURCE_SITE}.${PANTHEON_SOURCE_ENVIRONMENT} \
		--to=/tmp/database.sql.gz \
		--element=db
	zcat /tmp/database.sql.gz | mysql -h mysql -u tugboat -ptugboat drupal8

importfiles: check-env create-backup
	terminus backup:get \
		${PANTHEON_SOURCE_SITE}.${PANTHEON_SOURCE_ENVIRONMENT} \
		--to=/tmp/files.tar.gz \
		--element=files
	tar -C /tmp -zxf /tmp/files.tar.gz
	rsync -av --delete /tmp/files_${PANTHEON_SOURCE_ENVIRONMENT}/ /var/www/html/sites/default/files/
	chgrp -R www-data /var/www/html/sites/default/files
	chmod -R g+w /var/www/html/sites/default/files
	chmod 2775 /var/www/html/sites/default/files

build:
	composer install --no-ansi
	drush -r /var/www/html cr
	drush -r /var/www/html updb -y

clean:
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

check-env:
	@if [ -z $(PANTHEON_SOURCE_SITE) ]; then\
		echo "You must set the PANTHEON_SOURCE_SITE variable in your Tugboat repository settings";\
		exit 1;\
	fi;\
	if [ -z $(PANTHEON_SOURCE_ENVIRONMENT) ]; then\
		echo "You must set the PANTHEON_SOURCE_ENVIRONMENT variable in your Tugboat repository settings";\
		exit 1;\
	fi;\
	if [ -z $(PANTHEON_MACHINE_TOKEN) ]; then\
		echo "You must set the PANTHEON_MACHINE_TOKEN variable in your Tugboat repository settings";\
		exit 1;\
	fi;\

tugboat-init: packages createdb drupalconfig importdb importfiles build clean
tugboat-update: importdb importfiles build clean
tugboat-build: build
