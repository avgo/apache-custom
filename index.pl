#!/usr/bin/perl

use strict;
use utf8;

use Cwd;
use File::Basename;
use HTML::Template;

sub time_to_str {
	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime;

	$year += 1900;

	my @months = (
		"января",   "февраля",  "марта",
		"апреля",   "мая",      "июня",
		"июля",     "августа",  "сентября",
		"октября",  "ноября",   "декабря"
	);

	my @wdays = (qw(понедельник вторник среда четверг пятница суббота воскресенье));

	sprintf("%u %s %u, %s, %02u:%02u:%02u",
		$mday, $months[$mon], $year,
		$wdays[($wday+6)%7], $hour, $min, $sec);
}

my $template = HTML::Template->new(
        filename           => dirname(Cwd::abs_path($0)) . "/index.template.html",
        die_on_bad_params  => 0,
        utf8               => 1
);

$template->param(time_now => time_to_str());

print "Content-type: text/html\n\n", $template->output();
