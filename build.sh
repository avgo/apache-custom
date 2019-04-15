#!/bin/bash

script_rp="$(realpath "${0}")"          || exit 1
script_dir="$(dirname "${script_rp}")"  || exit 1

# config_rp="${script_dir}/build.sh.conf"

apache_port=8050
apache_prefix="${script_dir}-root"

load_config() {
	source "$config_rp" || exit 1
	if test x"$prefix" = x; then
		echo error: prefix must be specified. >&2
		exit 1
	fi
}

main() {
	test1 "$@"
}

test1() {
	cd "${script_dir}" || return 1
	make distclean
	rm -rf "${apache_prefix}"
	./configure --prefix="${apache_prefix}" --enable-cgi &&
	make &&
	make install

	# ServerRoot "%APACHE_SERVER_ROOT%"
	# Listen %APACHE_PORT%
	# PidFile %APACHE_PID%
	# DocumentRoot %APACHE_DEBIAN%

	local cf

	mkdir -v "${apache_prefix}"/{etc{,/httpd{,/conf,/logs}},var{,/run,/www{,/html}}}

	touch "${apache_prefix}/etc/httpd/mime.types"

	mv -v "${apache_prefix}/modules" "${apache_prefix}/etc/httpd"

	sed	-e "s@%APACHE_DEBIAN%@${apache_prefix}/var/www/html@g" \
		-e "s@%APACHE_PID%@${apache_prefix}/var/run/apache.pid@g" \
		-e "s@%APACHE_PORT%@${apache_port}@g" \
		-e "s@%APACHE_SERVER_ROOT%@${apache_prefix}/etc/httpd@g" \
		"httpd.conf.in" > "${apache_prefix}/etc/httpd/conf/httpd.conf"

	sed	-e "s@%INSTALL_TIME%@$(date +"%d.%m.%Y %T")@g" \
		"index.template.html" > "${apache_prefix}/var/www/html/index.html"

	cp -vf "index.pl" "${apache_prefix}/var/www/html"
}

main "$@"
