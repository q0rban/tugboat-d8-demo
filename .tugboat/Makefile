# Install a specific version of PHP by passing the version to this target. Use
# major and minor versions separated by a dot. For example, install-php-7.2.
.PHONY: install-php-%
install-php-%: ## Install a specific version of PHP by replacing the %, e.g. install-php-7.2.
	$(info Installing PHP $*...)
#	# Ensure PHP version is correctly formatted.
	@if [[ ! "$*" =~ ^[0-9]\.[0-9]$$ ]]; then\
		echo "PHP version $* is an invalid format.";\
		exit 1;\
	fi
#	# Ensure installed PHP version isn't the current version to be installed.
	@set -x; if [ "$*" = "${current_php_version}" ]; then\
		echo "Current PHP Version is already ${current_php_version}.";\
	else \
		$(minimal-package-install) python-software-properties software-properties-common;\
		LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php;\
		$(MAKE) -B packages-update;\
		$(minimal-package-install) \
			php$(*) \
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
			php$(*)-zip;\
		if [[ "$$TUGBOAT_SERVICE" == apache* ]]; then\
			$(MAKE) install-package-libapache2-mod-php$(*);\
			a2enmod php$(*);\
			a2dismod php$(current_php_version) || /bin/true;\
		elif [[ "$$TUGBOAT_SERVICE" == nginx* ]]; then\
			$(MAKE) install-package-php$(*)-fpm;\
			dpkg --purge apache2 libapache2-mod-php7.2 -y;\
		fi;\
		echo "PHP $(*) installed.";\
	fi
