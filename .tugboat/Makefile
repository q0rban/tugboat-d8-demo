# We need bash to use =~ regex tests in if statements.
SHELL := /bin/bash
# Turn off interactive mode in Composer for all subshells.
export COMPOSER_NO_INTERACTION := 1
# Determine the current php version. We use a recursively expanded variable so
# that it's only evaluated when we want the value.
current_php_version = $(shell php -r "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;")

# To keep things peppier, we can run apt-get update just once by having this as
# a dependency to install-package-%.
.PHONY: packages-update
packages-update:
	apt-get update

# Install an apt package by passing the value. For example, to install wget, use
# install-package-wget as the target.
.PHONY: install-package-%
install-package-%: packages-update
	apt-get install -y --no-install-recommends $(*)

# Installs the latest version of Composer. Note, you should use install-php-%
# first to ensure your desired version of PHP is installed.
.PHONY: install-composer
install-composer: install-package-wget
	$(info Installing Composer...)
#	# The following code is adapted from https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
	export EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig) &&\
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" &&\
	export ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

	if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then \
		>&2 echo 'ERROR: Invalid installer signature'; \
		rm composer-setup.php; \
		exit 1; \
	fi

	php composer-setup.php --install-dir=/tmp
	mv -f /tmp/composer.phar /usr/local/bin/composer
	rm composer-setup.php
	@echo "Composer installed."

# Installs the latest version of drush.
.PHONY: install-drush
install-drush: install-composer install-package-curl
	$(info Installing Drush...)
	composer --no-ansi global require drush/drush
	ln -sf /root/.composer/vendor/bin/drush /usr/bin/drush
	@echo "Drush installed."

# Installs the drush-launcher instead of drush.
.PHONY: install-drush-launcher
install-drush-launcher: install-package-wget
	wget -O /tmp/drush.phar https://github.com/drush-ops/drush-launcher/releases/download/0.6.0/drush.phar
	mv -f /tmp/drush.phar /usr/bin/drush
	chmod +x /usr/bin/drush
	@echo "Drush launcher installed."

# Install terminus for Pantheon sites.
.PHONY: install-terminus
install-terminus: install-composer
	$(info Installing Terminus...)
	curl -O https://raw.githubusercontent.com/pantheon-systems/terminus-installer/master/builds/installer.phar
	php installer.phar install
	@echo "Terminus installed."

# Install a specific version of PHP by passing the version to this target. Use
# major and minor versions separated by a dot. For example, install-php-7.2.
.PHONY: install-php-%
install-php-%:
	$(info Installing PHP $*...)
#	# Ensure PHP version is correctly formatted.
	@if [[ ! $* =~ ^[0-9]\.[0-9]$$ ]]; then\
		echo "PHP version $* is an invalid format.";\
		exit 1;\
	fi
#	# Ensure installed PHP version isn't the current version to be installed.
	@if [ $* = ${current_php_version} ]; then\
		echo "Current PHP Version is already ${current_php_version}.";\
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
		a2dismod php$(current_php_version) &&\
		echo "PHP $(*) installed.";\
	fi

# Install a specific version of nodejs by passing the version to this target.
# Use the major version only. For example, install-nodejs-9.
.PHONY: install-nodejs-%
install-nodejs-%: install-package-curl
	$(info Installing nodejs $*...)
#	# Ensure nodejs version is correctly formatted.
	@if [[ ! $* =~ ^[0-9]$$ ]]; then\
		echo "Version number $* is an invalid format. Specify the major version only.";\
		exit 1;\
	fi
	curl -sL https://deb.nodesource.com/setup_$(*).x | bash -
	apt-get install -y nodejs
	@echo "Installed nodejs $(*).x."
