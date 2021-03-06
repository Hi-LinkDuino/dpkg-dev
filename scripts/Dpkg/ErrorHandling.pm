# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

package Dpkg::ErrorHandling;

use strict;
use warnings;

our $VERSION = '0.02';
our @EXPORT_OK = qw(
    REPORT_PROGNAME
    REPORT_COMMAND
    REPORT_STATUS
    REPORT_INFO
    REPORT_NOTICE
    REPORT_WARN
    REPORT_ERROR
    report_pretty
    report_color
    report
);
our @EXPORT = qw(
    report_options
    info
    notice
    warning
    error
    errormsg
    syserr
    printcmd
    subprocerr
    usageerr
);

use Exporter qw(import);
use Term::ANSIColor;

use Dpkg ();
use Dpkg::Gettext;

my $quiet_warnings = 0;
my $info_fh = \*STDOUT;
my $use_color = 0;

sub setup_color
{
    my $mode = $ENV{'DPKG_COLORS'} // 'never';

    if ($mode eq 'auto') {
        ## no critic (InputOutput::ProhibitInteractiveTest)
        $use_color = 1 if -t *STDOUT or -t *STDERR;
    } elsif ($mode eq 'always') {
        $use_color = 1;
    } else {
        $use_color = 0;
    }
}

setup_color();

use constant {
    REPORT_PROGNAME => 1,
    REPORT_COMMAND => 2,
    REPORT_STATUS => 3,
    REPORT_INFO => 4,
    REPORT_NOTICE => 5,
    REPORT_WARN => 6,
    REPORT_ERROR => 7,
};

my %report_mode = (
    REPORT_PROGNAME() => {
        color => 'bold',
    },
    REPORT_COMMAND() => {
        color => 'bold magenta',
    },
    REPORT_STATUS() => {
        color => 'clear',
        # We do not translate this name because the untranslated output is
        # part of the interface.
        name => 'status',
    },
    REPORT_INFO() => {
        color => 'green',
        name => g_('info'),
    },
    REPORT_NOTICE() => {
        color => 'yellow',
        name => g_('notice'),
    },
    REPORT_WARN() => {
        color => 'bold yellow',
        name => g_('warning'),
    },
    REPORT_ERROR() => {
        color => 'bold red',
        name => g_('error'),
    },
);

sub report_options
{
    my (%options) = @_;

    if (exists $options{quiet_warnings}) {
        $quiet_warnings = $options{quiet_warnings};
    }
    if (exists $options{info_fh}) {
        $info_fh = $options{info_fh};
    }
}

sub report_name
{
    my $type = shift;

    return $report_mode{$type}{name} // '';
}

sub report_color
{
    my $type = shift;

    return $report_mode{$type}{color} // 'clear';
}

sub report_pretty
{
    my ($msg, $color) = @_;

    if ($use_color) {
        return colored($msg, $color);
    } else {
        return $msg;
    }
}

sub _progname_prefix
{
    return report_pretty("$Dpkg::PROGNAME: ", report_color(REPORT_PROGNAME));
}

sub _typename_prefix
{
    my $type = shift;

    return report_pretty(report_name($type), report_color($type));
}

sub report(@)
{
    my ($type, $msg) = (shift, shift);

    $msg = sprintf($msg, @_) if (@_);

    my $progname = _progname_prefix();
    my $typename = _typename_prefix($type);

    return "$progname$typename: $msg\n";
}

sub info($;@)
{
    print { $info_fh } report(REPORT_INFO, @_) if not $quiet_warnings;
}

sub notice
{
    warn report(REPORT_NOTICE, @_) if not $quiet_warnings;
}

sub warning($;@)
{
    warn report(REPORT_WARN, @_) if not $quiet_warnings;
}

sub syserr($;@)
{
    my $msg = shift;
    die report(REPORT_ERROR, "$msg: $!", @_);
}

sub error($;@)
{
    die report(REPORT_ERROR, @_);
}

sub errormsg($;@)
{
    print { *STDERR } report(REPORT_ERROR, @_);
}

sub printcmd
{
    my (@cmd) = @_;

    print { *STDERR } report_pretty(" @cmd\n", report_color(REPORT_COMMAND));
}

sub subprocerr(@)
{
    my ($p) = (shift);

    $p = sprintf($p, @_) if (@_);

    require POSIX;

    if (POSIX::WIFEXITED($?)) {
	error(g_('%s gave error exit status %s'), $p, POSIX::WEXITSTATUS($?));
    } elsif (POSIX::WIFSIGNALED($?)) {
	error(g_('%s died from signal %s'), $p, POSIX::WTERMSIG($?));
    } else {
	error(g_('%s failed with unknown exit code %d'), $p, $?);
    }
}

my $printforhelp = g_('Use --help for program usage information.');

sub usageerr(@)
{
    my ($msg) = (shift);

    $msg = sprintf($msg, @_) if (@_);
    warn report(REPORT_ERROR, $msg);
    warn "\n$printforhelp\n";
    exit(2);
}

1;
