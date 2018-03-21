all: packages drupalconfig createdb importdb importfiles build clean tugboat-build tugboat-init tugboat-update
.PHONY: all

define check_variables
ifndef PANTHEON_SOURCE_SITE
  $(error You must set the PANTHEON_SOURCE_SITE variable in your Tugboat repository settings)
endif
ifndef PANTHEON_SOURCE_ENVIRONMENT
  $(error You must set the PANTHEON_SOURCE_ENVIRONMENT variable in your Tugboat repository settings)
endif
ifndef PANTHEON_MACHINE_TOKEN
  $(error You must set the PANTHEON_MACHINE_TOKEN variable in your Tugboat repository settings)
endif
endef

packages:
	apt-get install -y python-software-properties software-properties-common
	add-apt-repository -y ppa:ondrej/php
	apt-get update
	apt-get install -y \
		php7.2 \
		php7.2-mbstring \
		php7.2-mysql \
		php7.2-xml \
		php7.2-zip \
		php7.2-bcmath \
		php7.2-bz2 \
		php7.2-cli \
		php7.2-common \
		php7.2-curl \
		php7.2-dev \
		php7.2-gd \
		php7.2-intl \
		php7.2-json \
		php7.2-mbstring \
		php7.2-mcrypt \
		php7.2-mysql \
		php7.2-opcache \
		php7.2-phpdbg \
		php7.2-pspell \
		php7.2-readline \
		php7.2-recode \
		php7.2-soap \
		php7.2-sqlite3 \
		php7.2-tidy \
		php7.2-xml \
		php7.2-xsl \
		php7.2-zip \
		libapache2-mod-php7.2 \
		mysql-client \
		rsync
	a2enmod php7.2
	a2dismod php7.0
	composer install --no-ansi --no-interaction
	ln -sf ${TUGBOAT_ROOT} /var/www/html
	# Install terminus
	curl -O https://raw.githubusercontent.com/pantheon-systems/terminus-installer/master/builds/installer.phar && php installer.phar install
	terminus auth:login --machine-token=$PANTHEON_MACHINE_TOKEN

drupalconfig:
	cp ${TUGBOAT_ROOT}/.tugboat/dist/settings.local.php ${TUGBOAT_ROOT}/sites/default/settings.local.php
	echo "\$$settings['hash_salt'] = '$$(openssl rand -hex 32)';" >> ${TUGBOAT_ROOT}/sites/default/settings.local.php

create-backup:
	terminus backup:create ${PANTHEON_SOURCE_SITE}.${PANTHEON_SOURCE_ENVIRONMENT}

createdb:
	mysql -h mysql -u tugboat -ptugboat -e "create database drupal8;"

importdb: create-backup
	terminus backup:get ${PANTHEON_SOURCE_SITE}.${PANTHEON_SOURCE_ENVIRONMENT} --to=/tmp/database.sql.gz --element=db
	zcat /tmp/database.sql.gz | mysql -h mysql -u tugboat -ptugboat drupal8

importfiles: create-backup
	terminus backup:get ${PANTHEON_SOURCE_SITE}.${PANTHEON_SOURCE_ENVIRONMENT} --to=/tmp/files.tar.gz --element=files
	tar -C /tmp -zxf /tmp/files.tar.gz
	rsync -av --delete /tmp/files_${PANTHEON_SOURCE_ENVIRONMENT}/ /var/www/html/sites/default/files/

build:
	drush -r /var/www/html cache-rebuild
	drush -r /var/www/html updb -y

clean:
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

check-env:
	$(call check_variables)

tugboat-init: check-env packages createdb drupalconfig importdb importfiles build clean
tugboat-update: check-env importdb importfiles build clean
tugboat-build: build
