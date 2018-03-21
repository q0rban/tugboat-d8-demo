MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
TUGBOAT_DIR := $(patsubst %/,%,$(dir $(MKFILE_PATH)))

export COMPOSER_NO_INTERACTION = 1
CURRENT_PHP_VERSION := $(shell php -r "echo PHP_MAJOR_VERSION .'.'. PHP_MINOR_VERSION;")

.PHONY: install-standard-packages
install-standard-packages:
	apt-get update
	apt-get install -y mysql-client rsync wget

.PHONY: install-composer
install-composer: install-standard-packages
	$(info Installing Composer...)
	@$(TUGBOAT_DIR)/bin/install-composer.sh

.PHONY: install-drush
install-drush: install-composer
	$(info Installing Drush...)
	composer --no-ansi global require drush/drush
	ln -sf /root/.composer/vendor/bin/drush /usr/bin/drush
	@echo "Drush installed."

.PHONY: install-terminus
install-terminus: install-composer
	$(info Installing Terminus...)
	@curl -O https://raw.githubusercontent.com/pantheon-systems/terminus-installer/master/builds/installer.phar &&\
	php installer.phar install &&\
	echo "Terminus installed."

.PHONY: install-php-%
install-php-%:
	$(info Installing PHP $*...)
#	# Ensure PHP version is correctly formatted.
	@if [[ ! $* =~ ^[0-9]\.[0-9]$ ]]; then\
		echo "PHP version $* is an invalid format.";\
		exit 1;\
	fi
#	# Ensure installed PHP version isn't the current version to be installed.
	@if [ $* = ${CURRENT_PHP_VERSION} ]; then\
		echo "Current PHP Version is already ${CURRENT_PHP_VERSION}.";\
		exit;\
	else \
		apt-get install -y python-software-properties software-properties-common &&\
		add-apt-repository -y ppa:ondrej/php &&\
		apt-get update &&\
		apt-get install -y \
			php$(*) \
			php$(*)-mbstring \
			php$(*)-mysql \
			php$(*)-xml \
			php$(*)-zip \
			php$(*)-bcmath \
			php$(*)-bz2 \
			php$(*)-cli \
			php$(*)-common \
			php$(*)-curl \
			php$(*)-dev \
			php$(*)-gd \
			php$(*)-intl \
			php$(*)-json \
			php$(*)-mbstring \
			php$(*)-mysql \
			php$(*)-opcache \
			php$(*)-phpdbg \
			php$(*)-pspell \
			php$(*)-readline \
			php$(*)-recode \
			php$(*)-soap \
			php$(*)-sqlite3 \
			php$(*)-tidy \
			php$(*)-xml \
			php$(*)-xsl \
			php$(*)-zip \
			libapache2-mod-php$(*) &&\
		a2enmod php$(*) &&\
		a2dismod php$(CURRENT_PHP_VERSION) &&\
		echo "PHP $(*) installed.";\
	fi

.PHONY: install-nodejs-%
install-nodejs-%:
	$(info Installing nodejs $*...)
#	# Ensure nodejs version is correctly formatted.
	@if [[ ! $* =~ ^[0-9]$$ ]]; then\
		echo "Version number $* is an invalid format. Specify the major version only.";\
		exit 1;\
	fi
	@curl -sL https://deb.nodesource.com/setup_$(*).x | bash - &&\
	apt-get install -y nodejs &&\
	echo "nodejs $(*).x installed."
