package RunApp::Template::Apache;
use base qw(RunApp::Template);
use strict;

sub get_template {
  my ($self, $conf) = @_;
  Template->new({ ABSOLUTE => 1,
		  DEBUG_UNDEF => 1,
		  BLOCKS => { extra => $conf->{config_block} },
		});
}

=head1 NAME

RunApp::Apache - Apache control from RunApp

=head1 SYNOPSIS

 See RunApp::Apache

=head1 DESCRIPTION

The class provides the default template for apache configuration.  It
uses L<Template Toolkit|Template>.

=head2 variables

=over

=item KeepAlive

Default is Off.

=item documentroot

=item hostname

=item port

=item webmaster

=item logformat

Default is 'common'.

=item AP_VERSION

Shows the version of the apache used.

=back

=head1 AUTHORS

Chia-liang Kao <clkao@clkao.org>

Refactored from works by Leon Brocard E<lt>acme@astray.comE<gt> and
Tom Insam E<lt>tinsam@fotango.comE<gt>.

=head1 COPYRIGHT

Copyright (C) 2002-5, Fotango Ltd.

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;


__DATA__
# DO NOT EDIT THIS FILE.
# Generated for Apache [% AP_VERSION %] by [% PACKAGE %]
[% BLOCK load_module %]
[% symbol = module _ "_module" %]
<IfModule !mod_[% module %].c>
    LoadModule [% symbol %] "[% LIBEXECDIR %]/mod_[% module %].so"
</IfModule>
[% END %]

ServerRoot "[% root %]"
PidFile [% pidfile %]
ScoreBoardFile [% logs %]/apache_runtime_status

Timeout 100

KeepAlive [% KeepAlive || 'Off' %]
MaxKeepAliveRequests 100
KeepAliveTimeout 2

MinSpareServers [% MinSpareServers %]
MaxSpareServers [% MaxSpareServers %]
StartServers [% StartServers %]
MaxClients [% MaxClients %]
MaxRequestsPerChild [% MaxRequestsPerChild %]

LockFile "[% logs %]/httpd.lock"

<IfModule mod_so.c>

[% FOR module IN required_modules %]
[% PROCESS load_module %]
[% END %]

</IfModule>

[% IF status %]
<IfModule mod_status.c>
  ExtendedStatus On
  <Location /status/perl/>
    SetHandler server-status
  </Location>
</IfModule>
[% END %]

ServerTokens      Prod
ServerSignature   Off
ServerName        [% hostname %]
ServerAdmin       [% webmaster %]
[% IF port %]
Listen		  [% port %]
[% END %]

User [% user %]
Group [% group %]

DocumentRoot "[% documentroot || cwd %]"

<IfModule mod_mime.c>
    TypesConfig [% mime_file %]
</IfModule>

DefaultType text/plain

HostnameLookups Off

ErrorLog "[% logs %]/error_log"

LogLevel warn

LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %b (%{stopwatch}n usecs)" stopwatch
LogFormat "%h %l %u %t \"%r\" %>s %b" common
LogFormat "%{Referer}i -> %U" referer
LogFormat "%{User-agent}i" agent

[% IF cronolog.binary %]
CustomLog  "|[% cronolog.binary %] [% logs %]/[% cronolog.access_format %]" [% logformat || 'common' %]
[% ELSE %]
CustomLog "[% logs %]/access_log"  [% logformat || 'common' %]
[% END %]

CoreDumpDirectory /tmp

<IfModule mod_perl.c>
<Perl>
[% IF AP_VERSION == 2 %]
eval { use Apache2 };
eval { use Apache::compat };
[% END %]

[% IF cover %]
use Devel::Cover
[% IF cover_arg %]
 qw([% cover_arg %]);
[% END %];
[% END %]

[% IF profiler %]
require Profiler::Apache;
[% END %]

</Perl>
</IfModule>

[% PROCESS extra %]
