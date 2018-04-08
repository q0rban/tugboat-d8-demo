# Pantheon Makefile template for Tugboat

# Please modify the following environment variables to match your project.
# Specify the desired version of PHP in major.minor format, e.g. 7.1.
PHP_VERSION := 7.2
# Specify the Drupal site, which corellates to the name of the directory in
# your Drupal /sites directory. This is typically just default unless you are
# using Drupal multisite.
DRUPAL_SITE := default
# Specify the location of the directory that is the web root of the site,
# relative to the repo root, i.e. $TUGBOAT_ROOT. For example, if /web is where
# Drupal is installed, set DRUPAL_ROOT = ${TUGBOAT_ROOT}/web.
DRUPAL_ROOT = ${TUGBOAT_ROOT}
# This is the directory where you might keep configuration files that need to
# be distributed into your project for Tugboat, such as Drupal's settings.php
# or a .env specific to Tugboat.
DIST_DIR = ${TUGBOAT_ROOT}/.tugboat/dist

# Tugboat services have a handy Makefile in /usr/share/tugboat that we can use
# to simplify our setup process. We include that here. If you're curious what
# that gives you, you can run 'make -C /usr/share/tugboat' from any Tugboat
# service.
-include /usr/share/tugboat/Makefile

# Install our desired packages, including the PHP version we specified above,
# Composer, Terminus, and Drush.
packages: check-env install-php-$(PHP_VERSION) install-composer install-terminus install-drush
#	# Point the www dir that is served to the drupal root.
	ln -sf ${DRUPAL_ROOT} ${WWW_DIR}
#	Authenticate to terminus
	terminus auth:login --machine-token=${PANTHEON_MACHINE_TOKEN}
#	# Run composer install on this repo.
	composer install --no-ansi

drupalconfig:
#	# Copy the settings.local.php that works for Tugboat into sites/default.
	cp ${DIST_DIR}/settings.local.php ${DRUPAL_SITE_DIR}/settings.local.php
#	# Generate a hash_salt to secure the site.
	echo "\$$settings['hash_salt'] = '$$(openssl rand -hex 32)';" >> ${DRUPAL_SITE_DIR}/settings.local.php

create-backup: check-env
	terminus backup:create ${PANTHEON_SOURCE_SITE}.${PANTHEON_SOURCE_ENVIRONMENT}

createdb:
	$(DRUSH) sql-create -y

importdb: check-env create-backup
	terminus backup:get \
		${PANTHEON_SOURCE_SITE}.${PANTHEON_SOURCE_ENVIRONMENT} \
		--to=/tmp/database.sql.gz \
		--element=db
#	# Clean out all existing tables.
	${DRUSH} sql-drop
#	# Import the new database dump.
	zcat /tmp/database.sql.gz | ${DRUSH} sql-cli
#	# Sanitize the new database dump.
	${DRUSH} sqlsan --sanitize-password=tugboat

importfiles: check-env create-backup
	terminus backup:get \
		${PANTHEON_SOURCE_SITE}.${PANTHEON_SOURCE_ENVIRONMENT} \
		--to=/tmp/files.tar.gz \
		--element=files
	tar -C /tmp -zxf /tmp/files.tar.gz
	rsync -av --delete /tmp/files_${PANTHEON_SOURCE_ENVIRONMENT}/ ${DRUPAL_SITE_DIR}/files/
#	# Fix up file permissions so that the www user can read and write.
	chgrp -R www-data ${DRUPAL_SITE_DIR}/files
	chmod -R g+w ${DRUPAL_SITE_DIR}/files
	chmod 2775 ${DRUPAL_SITE_DIR}/files

build:
# 	# Rather than specify each of these steps here, it's recommended to create a
#	# script or command that encapsulates all your build steps that all
#	# environments can use, including local, Dev, Test, Prod, and Tugboat.
	composer install --no-ansi
	${DRUSH} cr
	${DRUSH} updb

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

tugboat-init: packages drupalconfig createdb importdb importfiles build cleanup
tugboat-update: importdb importfiles build cleanup
tugboat-build: build

#########
# There is often no need to modify anything below here.
DRUSH := drush -y --root=${DRUPAL_ROOT} --uri=${TUGBOAT_URL}
# The directory that the web server serves the site from. On Apache services
# this is /var/www/html. On Nginx services, it is /usr/share/nginx/html.
ifneq (,$(findstring nginx, $(TUGBOAT_SERVICE)))
  WWW_DIR := /usr/share/nginx/html
else
  WWW_DIR := /var/www/html
endif
# The path to the Drupal site dir.
DRUPAL_SITE_DIR := ${DRUPAL_ROOT}/sites/${DRUPAL_SITE}
