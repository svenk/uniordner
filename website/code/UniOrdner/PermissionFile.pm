package UniOrdner::PermissionFile;

use strict;
use warnings;

#use base 'Exporter';
#our @EXPORT_OK = qw/PERM_OPEN PERM_PUBLIC PERM_PASSWORD PERM_PROTECTED PERM_PRIVATE/;

use Log::Log4perl qw(:easy);

use Data::Dumper;
use Text::Glob qw/match_glob/; # libtext-glob-perl bei ubuntu
use File::Spec::Functions qw(splitpath splitdir catdir);
use File::Basename;

# Permission policies
use constant {
	PERM_OPEN =>      10,
	PERM_PUBLIC =>    20,
	PERM_PASSWORD =>  30,
	PERM_PROTECTED => 40,
	PERM_PRIVATE =>   50,
	PERM_UNDEFINED => 0
};

# Access policies
use constant {
	ACCESS_OK => 0,
	ACCESS_PASSWORD => 1,
	ACCESS_FORBIDDEN => 2,
};

our $default_shorthand_permission = PERM_PUBLIC; # for shorthand notation in permission files
our $default_empty_permission = PERM_PRIVATE; # if file not mentioned in permission file
our $default_permission_filename = "permissions.txt";
our $root_directory; # = "/srv/www/uni"; # without trailing slash!

sub printable_access {
	my ($this, $value) = @_;
	my %printables = (
		ACCESS_OK()=>"Access granted",
		ACCESS_PASSWORD()=>"Access with password",
		ACCESS_FORBIDDEN()=>"Access forbidden");
	return $printables{$value};
}

sub printable_permission {
	my ($this, $value) = @_;
	my %printables = (
		PERM_OPEN() =>      "open",
		PERM_PUBLIC() =>    "public",
		PERM_PASSWORD() =>  "password",
		PERM_PROTECTED() => "protected",
		PERM_PRIVATE() =>   "private",
		PERM_UNDEFINED() => "undefined");
	return $printables{$value};
}

sub parse_permission_directory {
	# in detail parsing of permission file and matching with
	# according directory. Expects permission file or according
	# directory, will output hash like
	my ($this, $dirname) = @_;
	return {} unless -e $dirname;

	# read in real files in directory
	opendir(my $dh, $dirname) || return {};
	my @real_files = grep !/^\./, readdir($dh);
	closedir($dh);
	
	return UniOrdner::PermissionFile->match_permissions($dirname, @real_files);
}

sub has_permission_file {
	# check if given directory has a permission file present.
	# PermissionFile->has_permision_file("/name/of/directory");
	# @returns boolean
	my $this = shift;
	my $dirname = shift;
	my $permfile = "$dirname/$default_permission_filename";
	return -e $permfile;
}

sub match_permissions {
	# having an array with filenames, permission file and directory,
	# give out a hash like
	# { "filename" => PERM_OPEN, "filename2" => PERM_PASSWORD, ... }
	my $this = shift;
	my $dirname = shift;
	my $files = shift; # array or string
	return {} if(!-d $dirname);
	my $permfile = "$dirname/$default_permission_filename";
	unless(-e $permfile) {
		return {map { $_=>PERM_UNDEFINED } @$files} if(ref($files));
		return PERM_UNDEFINED;
	}

	my $pfh; # permfilehandle
	open($pfh, "<$permfile") || warn "Cannot open $permfile: $!\n";
	if(ref($files)) {
		my %perms;
		foreach(@$files) { $perms{$_} = PERM_UNDEFINED; }
		while(<$pfh>) {
			next if /^(#|\s*$)/;
			my $line_perms = parse_perm_entry($_, $files);
			foreach(keys %$line_perms) {
				# don't be greedy: Wenn es schon eine regel gibt, diese beibehalten und
				# nicht ueberschreiben. Dadurch koennen permission files vom speziellen
				# ins Allgemeine gehen, was halt als erstes matcht.
				$perms{$_} = $line_perms->{$_} if($line_perms->{$_} and not $perms{$_});
			}
		}
		close($pfh);
		return \%perms;
	} else {
		my $file = shift;
		while(<$pfh>) {
			next if /^(#|\s*$)/;
			my $perm = parse_perm_entry($_, $file);
			return $perm if($perm != PERM_UNDEFINED);
		}
		close($pfh);
		return PERM_UNDEFINED;
	}
}

sub parse_perm_entry {
	# parse one line in a permission file, which has the form
	# "filepattern: permission" (first argument to the function).
	# second argument is a filename or a list of filenames.
	# if wantarray, gives a {filename=>permission,...} hash back.
	# else the value PERM_* which this line represents, _UNDEFINED
	# if the line doesn't match any given filename.
	my ($line, $target) = @_; # target string or ref(@array)
	my ($pattern, $permission) = split /:/, $line;
	$permission = $default_shorthand_permission unless $permission;
	# quick and dirty trimming
	$pattern =~ s/^\s*//; $pattern =~ s/\s*$//;
	$permission =~ s/^\s*//; $permission =~ s/\s*$//;
	# check if the rule matches
	my @m = match_glob($pattern, ref($target)?@$target:$target);
	my $perm = PERM_UNDEFINED;
	if(@m) {
		if($permission eq 'open') {
			$perm = PERM_OPEN;
		} elsif($permission eq 'public') {
			$perm = PERM_PUBLIC;
		} elsif($permission eq 'password') {
			$perm = PERM_PASSWORD;
		} elsif($permission eq 'protected') {
			$perm = PERM_PROTECTED;
		} else {
			$perm = PERM_PRIVATE;
		}
	}
	if(ref($target)) {
		my %r = ();
		foreach my $n (@$target) { $r{$n} = PERM_UNDEFINED; }
		foreach my $y (@m) { $r{$y} = $perm; }
		return \%r;
	} else {
		return $perm;
	}
}

sub quick_check_permission {

Log::Log4perl->easy_init({
	level => $INFO,
	file => ">> /tmp/permissions.log",
});
	# erwartet sowas wie
	# /pfad/zur/datei  /pfad/zum/ordner  /pfad/zum/ordner/
	# behandelt Dateien und Ordner gleich und prueft jeweils in
	# /pfad und /zur auf die permission-Datei. Parst diese
	# dann schnell und bricht ab, sobald Regel gefunden.

	my ($this, $filepath, $root_directory, $logger) = @_; # /pfad/zur/relevanten/datei oder ordner
	INFO("Checking quick permissions on $filepath");
	return ACCESS_OK unless(-e $filepath); # gibts ja eh nicht.
	# das lassen wir mal nett wie wir sind:
	#my ($volume, $dir, $file) = splitpath($filepath);
	# achtung, pfad aufräumen!? Cwd::realpath etwa. File::Spec::canonpath
	# macht das nicht.
	my $is_dir = -d $filepath;
	# filepath chrooten:
	$filepath =~ s#^$root_directory##;
	INFO("Chrooted path to $filepath");
	return ACCESS_OK if($filepath =~ m#^/?$#); # root dir = enable access.
	my @dirs = splitdir($filepath); #grep !/^$/, splitdir($filepath);
	my $is_open = 1; # will be != 0 if directory structure is opened somewhere.
	for(my $x=0; $x<@dirs-1; $x++) {
		my $dirname = $root_directory. catdir(@dirs[0..$x]);
		my $permfile = "$dirname/$default_permission_filename";
		my $target = $dirs[$x+1];
		last unless($target);
		INFO("$x. Enter $dirname and looking on $target");
		if(-e $permfile) {
			$is_open--; # any permission file disables 'open'-status again.
			open(PERM, "<$permfile");
			INFO("$x. Parsing $permfile\n");
			while(<PERM>) {
				next if /^(#|\s*$)/;
				my $perm = parse_perm_entry($_, $target);
				if($perm == PERM_UNDEFINED) {
					next;
				} else {
					INFO("$x. Line $_ matched on $target");
				}
				if($perm == PERM_OPEN) {
					INFO("$x. $target is open. Continue.");
					$is_open = 1;
					last; # break parsing this file and continue to others.
				} elsif($perm == PERM_PUBLIC) {
					# Rechnung bei Ordnern:
					# Pfad:    /pfad/zum/ordner/
					# @dirs= '','pfad','zum','ordner','' (@dirs=5)
					# $x                x=3   => x==@dirs-2 => final public
					# Bei Dateien ist @dirs=4, ergo eins weniger.
					if($x+1 == ($is_dir ? @dirs-2 : @dirs-1)) {
						INFO("$x. End of path. Final is public.");
						return ACCESS_OK;
					} else {
						INFO("$x. Public, but Not end of path. Going on.");
						last;
					}
				} elsif($perm == PERM_PASSWORD || $perm == PERM_PROTECTED) {
					INFO("$x. $target is password/protected.");
					return ACCESS_PASSWORD;
				} else {
					INFO("$x. $target is private by permissionfile.");
					return ACCESS_FORBIDDEN;
				}
			} # while permfile
		} else { # -e permfile
			INFO("$x. No $permfile present");
		}
	} # for directories
	if($is_open == 1) {
		INFO("Access granted throught opened Path.");
		return ACCESS_OK;
	} else {
		INFO("Access forbidden throught no permission matching.");
		return ACCESS_FORBIDDEN;
	}
}



1;
