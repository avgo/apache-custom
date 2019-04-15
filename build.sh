#!/bin/bash

script_rp="$(realpath "${0}")"          || exit 1
script_dir="$(dirname "${script_rp}")"  || exit 1

# config_rp="${script_dir}/build.sh.conf"

apache_distrib="$(realpath "${script_dir}/../httpd-2.4.37")"
apache_port=8050
apache_prefix="${apache_distrib}-root"

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
	local apache_pid_rp="${apache_prefix}/var/run/apache.pid"

	if test -f "${apache_pid_rp}"; then
		echo "Apache server is running."
		echo "Stopping Apache server..."
		echo "${apache_prefix}/bin/apachectl" -f "${apache_prefix}/etc/httpd/conf/httpd.conf" -k stop
		"${apache_prefix}/bin/apachectl" -f "${apache_prefix}/etc/httpd/conf/httpd.conf" -k stop
		sleep 2
		if test -f "${apache_pid_rp}"; then
			echo "error: can't stop Apache server, pidfile still exists." >&2
			return 1
		fi
	fi

	cd "${apache_distrib}" || return 1
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
		"${script_dir}/httpd.conf.in" > "${apache_prefix}/etc/httpd/conf/httpd.conf"

	sed	-e "s@%INSTALL_TIME%@$(date +"%d.%m.%Y %T")@g" \
		"${script_dir}/index.template.html" > "${apache_prefix}/var/www/html/index.html"

	cp -vf "${script_dir}/index.pl" "${apache_prefix}/var/www/html"
	chmod -v +x "${apache_prefix}/var/www/html/index.pl"

	"${apache_prefix}/bin/apachectl" -f "${apache_prefix}/etc/httpd/conf/httpd.conf"

	sleep 2; if test -f "${apache_pid_rp}"; then
		echo "Apache server is running (pidfile exists)."
	else
		echo "Apache server is not running (pidfile not exists)."
	fi
}

main "$@"
