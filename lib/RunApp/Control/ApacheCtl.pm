package RunApp::Control::ApacheCtl;
use strict;
use base qw(RunApp::Template RunApp::Control);

sub dispatch {
  my ($self, $cmd) = @_;
  system ($self->{file}, $cmd);
  # XXX: handle error
  die $! if $?;
}

=head1 NAME

RunApp::Control::ApacheCtl - Class for invoking apachectl

=head1 SYNOPSIS

 see RunApp::Apache

=head1 DESCRIPTION

The class writes to the F<apachectl>-style control file with
L<Template> in the C<build> phase of L<RunApp>, and invokes it in
other phases.

=head1 SEE ALSO

L<RunApp::Template>, L<RunApp::Apache>

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
#!/bin/sh
#
# Apache control script designed to allow an easy command line interface
# to controlling Apache.  Written by Marc Slemko, 1997/08/23
# 
# The exit codes returned are:
#	0 - operation completed successfully
#	1 - 
#	2 - usage error
#	3 - httpd could not be started
#	4 - httpd could not be stopped
#	5 - httpd could not be started during a restart
#	6 - httpd could not be restarted during a restart
#	7 - httpd could not be restarted during a graceful restart
#	8 - configuration syntax error
#
# When multiple arguments are given, only the error from the _last_
# one is reported.  Run "apachectl help" for usage info
#
#
# |||||||||||||||||||| START CONFIGURATION SECTION  ||||||||||||||||||||
# --------------------                              --------------------
# 
# the path to your PID file
PIDFILE=[% pidfile %]
#
# the path to your httpd binary, including options if necessary
HTTPD="[% binary || httpd %] -f [% config_file %]"
#
# a command that outputs a formatted text version of the HTML at the
# url given on the command line.  Designed for lynx, however other
# programs may work.  
LYNX="lynx -dump"
#
# the URL to your server's mod_status status page.  If you do not
# have one, then status and fullstatus will not work.
STATUSURL="http://localhost/server-status"
#
# --------------------                              --------------------
# ||||||||||||||||||||   END CONFIGURATION SECTION  ||||||||||||||||||||

ERROR=0
ARGV="$@"
if [ "x$ARGV" = "x" ] ; then 
    ARGS="help"
fi

for ARG in $@ $ARGS
do
    # check for pidfile
    if [ -f $PIDFILE ] ; then
	PID=`cat $PIDFILE`
	if [ "x$PID" != "x" ] && kill -0 $PID 2>/dev/null ; then
	    STATUS="httpd (pid $PID) running"
	    RUNNING=1
	else
	    STATUS="httpd (pid $PID?) not running"
	    RUNNING=0
	fi
    else
	STATUS="httpd (no pid file) not running"
	RUNNING=0
    fi

    case $ARG in
    start)
	if [ $RUNNING -eq 1 ]; then
	    echo "$0 $ARG: httpd (pid $PID) already running"
	    continue
	fi
	if $HTTPD ; then
	    echo "$0 $ARG: httpd started"
	else
	    echo "$0 $ARG: httpd could not be started"
	    ERROR=3
	fi
	;;
    stop)
	if [ $RUNNING -eq 0 ]; then
	    echo "$0 $ARG: $STATUS"
	    continue
	fi
	if kill $PID ; then
	    echo "$0 $ARG: httpd stopped"
	else
	    echo "$0 $ARG: httpd could not be stopped"
	    ERROR=4
	fi
	;;
    restart)
	if [ $RUNNING -eq 0 ]; then
	    echo "$0 $ARG: httpd not running, trying to start"
	    if $HTTPD ; then
		echo "$0 $ARG: httpd started"
	    else
		echo "$0 $ARG: httpd could not be started"
		ERROR=5
	    fi
	else
	    if $HTTPD -t >/dev/null 2>&1; then
		if kill -HUP $PID ; then
		    echo "$0 $ARG: httpd restarted"
		else
		    echo "$0 $ARG: httpd could not be restarted"
		    ERROR=6
		fi
	    else
		echo "$0 $ARG: configuration broken, ignoring restart"
		echo "$0 $ARG: (run 'apachectl configtest' for details)"
		ERROR=6
	    fi
	fi
	;;
    graceful)
	if [ $RUNNING -eq 0 ]; then
	    echo "$0 $ARG: httpd not running, trying to start"
	    if $HTTPD ; then
		echo "$0 $ARG: httpd started"
	    else
		echo "$0 $ARG: httpd could not be started"
		ERROR=5
	    fi
	else
	    if $HTTPD -t >/dev/null 2>&1; then
		if kill -USR1 $PID ; then
		    echo "$0 $ARG: httpd gracefully restarted"
		else
		    echo "$0 $ARG: httpd could not be restarted"
		    ERROR=7
		fi
	    else
		echo "$0 $ARG: configuration broken, ignoring restart"
		echo "$0 $ARG: (run 'apachectl configtest' for details)"
		ERROR=7
	    fi
	fi
	;;
    status)
	$LYNX $STATUSURL | awk ' /process$/ { print; exit } { print } '
	;;
    fullstatus)
	$LYNX $STATUSURL
	;;
    configtest)
	if $HTTPD -t; then
	    :
	else
	    ERROR=8
	fi
	;;
    *)
	echo "usage: $0 (start|stop|restart|fullstatus|status|graceful|configtest|help)"
	cat <<EOF

start      - start httpd
stop       - stop httpd
restart    - restart httpd if running by sending a SIGHUP or start if 
             not running
fullstatus - dump a full status screen; requires lynx and mod_status enabled
status     - dump a short status screen; requires lynx and mod_status enabled
graceful   - do a graceful restart by sending a SIGUSR1 or start if not running
configtest - do a configuration syntax test
help       - this screen

EOF
	ERROR=2
    ;;

    esac

done

exit $ERROR

## ====================================================================
## The Apache Software License, Version 1.1
##
## Copyright (c) 2000-2002 The Apache Software Foundation.  All rights
## reserved.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions
## are met:
##
## 1. Redistributions of source code must retain the above copyright
##    notice, this list of conditions and the following disclaimer.
##
## 2. Redistributions in binary form must reproduce the above copyright
##    notice, this list of conditions and the following disclaimer in
##    the documentation and/or other materials provided with the
##    distribution.
##
## 3. The end-user documentation included with the redistribution,
##    if any, must include the following acknowledgment:
##       "This product includes software developed by the
##        Apache Software Foundation (http://www.apache.org/)."
##    Alternately, this acknowledgment may appear in the software itself,
##    if and wherever such third-party acknowledgments normally appear.
##
## 4. The names "Apache" and "Apache Software Foundation" must
##    not be used to endorse or promote products derived from this
##    software without prior written permission. For written
##    permission, please contact apache@apache.org.
##
## 5. Products derived from this software may not be called "Apache",
##    nor may "Apache" appear in their name, without prior written
##    permission of the Apache Software Foundation.
##
## THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED
## WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
## OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
## DISCLAIMED.  IN NO EVENT SHALL THE APACHE SOFTWARE FOUNDATION OR
## ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
## SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
## LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
## USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
## ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
## OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
## OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
## SUCH DAMAGE.
## ====================================================================
##
## This software consists of voluntary contributions made by many
## individuals on behalf of the Apache Software Foundation.  For more
## information on the Apache Software Foundation, please see
## <http://www.apache.org/>.
##
## Portions of this software are based upon public domain software
## originally written at the National Center for Supercomputing Applications,
## University of Illinois, Urbana-Champaign.
##
# 
