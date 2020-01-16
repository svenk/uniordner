package UniOrdner::AutoIndex;

use strict;
use warnings;

# configuration: simple!
our %template_file = ( # relative to uniroot directory
	'desktop' => 'code/skins/classic/autoindex-template.htm',
	'mobile' =>  'code/skins/mobile/autoindex-template.htm',
	'modern' => 'code/skins/modern/autoindex-template.htm');
our $default_template_name = "modern";
our @data_fields = qw/name href lastmod size type permission is_dir/;
our @ignore_regex = ('^permissions.txt.*$', '^\\.|~$'); # sort out unwanted dir entries
our $readme_regex = 'readme.(html?|txt)'; #i
our @indexfiles = qw/index.html index.htm/;
our $cookie_name = 'uniordner_view'; # name for cookie to store template choice

use UniOrdner::PermissionFile;
use Template; # Template Toolkit
use Data::Dumper;
use File::Spec::Functions qw(catfile splitpath splitdir catdir updir);
use Apache2::Const qw(:common :types);
use Apache2::RequestRec;
use Apache2::Log;
use Apache2::URI;
use Apache2::RequestIO;
use APR::Table; # headers tables
use POSIX qw(strftime);
use File::Basename; # dirname, 2017-11-03

sub handler {
	# according to Apache2::AutoIndex::XSLT and Apache::AutoIndex
	my $r = shift;
	return Apache2::Const::DECLINED unless $r->content_type
		and $r->content_type eq Apache2::Const::DIR_MAGIC_TYPE;
	
	# Make sure we're at a URL with a trailing slash
	if($r->uri !~ m,/$,) {
		$r->headers_out->add(Location => sprintf('%s/%s',
			$r->uri, ($r->args ? '?'.$r->args : '')));
		return Apache2::Const::REDIRECT;
	}
	
	$r->content_type('text/html');
	return Apache2::Const::OK if $r->header_only;
	
	# Make sure there is no index file
	foreach(@indexfiles) {
		my $file = $r->filename . $_;
		if(-e $file) {
			$r->sendfile($file);
			return Apache2::Const::OK;
		}
	}
	
	# collect the data
	my $data = {};
	$data->{'files'} = []; # list of files (see collect_data).
	my $ret = collect_data($data, $r->filename, $r);
	collect_global_data($data, $r);
	#print Dumper($data);

	# correct template (browser choice)
	my $inc_template_file = get_template_file($r);

	# Uni Root directory, like /srv/www/uni
	my $uniroot = $r->dir_config->get('uniroot');
	
	# Root directory of Uni Directory in URI ($r->uri), like
	# /uni/foo/bar => "/uni" to seperate /foo/bar
	my $uniwebroot = $r->dir_config->get('uniwebroot');
	
	my $template = Template->new({
		#INCLUDE_PATH => '/srv/www/uni/code',
		ABSOLUTE => 1, RELATIVE => 1, INTERPOLATE => 1
	});
	$template->process("$uniroot/$inc_template_file", $data)
		|| $r->print("Errors at templating: ". $template->error());

	return Apache2::Const::OK;
}

sub get_template_file {
	# detects user choice of template by cookie or GET request. A GET request
	# will fire a cookie store.
	my ($r) = @_;
	
	# get cookies
	my %cookies = defined($ENV{'HTTP_COOKIE'}) ? map { split /=/, $_, 2 } split /; /, $ENV{'HTTP_COOKIE'} : ();
	my $choice = $cookies{$cookie_name} if(exists $cookies{$cookie_name});
	if($r->args =~ /view=(desktop|mobile|modern)/i) {
		$cookies{$cookie_name} = my $newchoice = $1;
		# this could overwrite all cookies (dirty code)
		$r->headers_out->add('Set-Cookie' => "$cookie_name=$newchoice; Path=/uni");
		$choice = $newchoice;
	}
	
	return defined($choice) && exists($template_file{$choice}) ? $template_file{$choice} : $template_file{$default_template_name};
}

sub collect_data {
	# simply returns a list with a hash for each file, with
	# key entries like in $data_fields. $return_value should be
	# something like Apache2::Const::OK.
	# ($return_value, [ { name=>"a", lastmod=>"..", size=>".." },
	#   { name=>"b", ...                       },
	#   ...
	# ])
	my ($data, $dirname, $r) = @_;
	my $dh;
	if(!opendir($dh, $dirname)) {
		$r->log_reason(
			sprintf("%s Unable to open dir '%s': %s", __PACKAGE__, $dirname, $!),
			sprintf('%s (%s)', $r->uri, $dirname)
		);
		return Apache2::Const::FORBIDDEN;
	}
	
	while(my $file = readdir($dh)) {
		my %filehash;

		next if $file eq '..' || $file eq '.';
		next if grep($file =~ /$_/, @ignore_regex);
		my $filename = catfile($dirname, $file);
		my %stat;
		@stat{qw(dev ino mode nlink uid gid rdev size
			atime mtime ctime blksize blocks)} = lstat($filename);
		foreach my $f (@data_fields) {
			no strict 'refs';
			$filehash{$f} = &{"data_$f"}($file, $dirname, \%stat, $r);
		}
		push(@{$data->{'files'}}, \%filehash);
	}
	
	closedir($dh);
}

sub collect_global_data {
	# called after $data->{files} was filled.
	my ($data, $r) = @_;
	$data->{'path'} = $r->uri,
	$data->{'href'} = $r->construct_url;
	my $uniwebroot = $r->dir_config->get('uniwebroot');
	my $reluri;
	if($uniwebroot) {
		$uniwebroot = quotemeta $uniwebroot;
		$reluri = ($r->uri =~ s/$uniwebroot//r);
		$data->{'is_top'} = ($reluri =~ m#^/[^/]+/?$#) ?1:0;
	}
	$data->{'logged_in'} = $r->headers_in->{Authorization} ? 1 : 0; # da $r->usr nicht valid
	
	my @files = map { $_->{'name'} } @{$data->{'files'}};
	
	# look for a readme file:
	my @readme_files = grep(m#$readme_regex#i, @files);
	$data->{'readme_file'} = $r->filename.'/'.$readme_files[0] if(@readme_files);

	# get the readme content:
	if($data->{'readme_file'}) {
		require UniOrdner::ReadmeFile;
		# print_readme is a function which is supposed to be called like
		#    print_readme("plain", readme_file)
		# from the template. The 2nd argument is ugly, but there is no
		# simple way to access the local scope variables from outside the
		# anonymous function.
		$data->{'print_readme'} = sub {
			my $format = shift; # "markdown", "plain" allowed
			my $filename = shift; # shall be $data{'readme_file'}, but is not accessible from subroutine
			my $method = "get_${format}_readme_file";
			return UniOrdner::ReadmeFile->$method($filename);
		};
	}
	
	# check whats about the permission files. Do we have some?
	# (Stored in $data just for fast copy to $info in code)
	$data->{'has_permfile'} = UniOrdner::PermissionFile->has_permission_file($r->filename);
	# $data->{'parent_has_permfile'} = UniOrdner::PermissionFile->has_permission_file(updir($r->filename)); # fix 2017-11-03
	$data->{'parent_has_permfile'} = UniOrdner::PermissionFile->has_permission_file(dirname($r->filename));

	# common path debugging stuff
	my $path_info = $data->{'paths'} = {};
	$path_info->{'uniroot'} = $r->dir_config->get('uniroot');
	$path_info->{'uri'} = $r->uri;
	$path_info->{'uniwebroot'} = $r->dir_config->get('uniwebroot');
	if(length $reluri) {
		$path_info->{'reluri'} = $reluri;
	}
	
	# common directory info stuff for debugging
	my $info = $data->{dirinfo} = {};
	$info->{'readme_name'} = $data->{'readme_file'} || 'no readme file';
	foreach(qw/is_top logged_in has_permfile parent_has_permfile/) {
		$info->{$_} = $data->{$_}?'yes':'no';}

	# statistics for permission stuff:
	my $c = $data->{counter} = {};
	foreach(qw/viewable nonviewable private public password protected open undefined/) {
		$c->{$_} = 0; }
	
	# collect that permission stuff for this directory.
	my $permissions = UniOrdner::PermissionFile->match_permissions($r->filename, \@files);
	
	# check if the query was bad - eg no permfile available
	if($permissions == UniOrdner::PermissionFile::PERM_UNDEFINED) {
		if(!$data->{'has_permfile'} && $data->{'parent_has_permfile'}) {
			# TODO: Calculate and display permissions correctly!!
		}
	}
	
	foreach(@{$data->{'files'}}) {
		my $p = $_->{'permission_numeric'} = $permissions->{$_->{'name'}};
		$_->{'permission'} = UniOrdner::PermissionFile->printable_permission($p);
		$c->{$_->{'permission'}}++; # statistics!
		$_->{'can_view'} =
			($data->{'logged_in'} && ($p != UniOrdner::PermissionFile::PERM_PRIVATE))
			|| (!$data->{'logged_in'} && ($p != UniOrdner::PermissionFile::PERM_PASSWORD
				&& $p != UniOrdner::PermissionFile::PERM_PROTECTED
				&& $p != UniOrdner::PermissionFile::PERM_PRIVATE));
		$c->{$_->{'can_view'} ? 'viewable' : 'nonviewable'}++; # statistics!
	}
	#print Dumper($data);
	
	# now do sorting stuff
	# sort files by name
	$data->{'files'} = [sort { $a->{name} cmp $b->{name} } @{$data->{'files'}}];
	# sort directories on top
	$data->{'files'} = [sort { $b->{is_dir} <=> $a->{is_dir} } @{$data->{'files'}}];
	unless($data->{'logged_in'}) {
		# sort materials after increasing permission level
		$data->{'files'} = [sort { $a->{permission_numeric} <=> $b->{permission_numeric} } @{$data->{'files'}}];
	}
	
	# filter materials out
	unless($data->{'logged_in'}) {
		# public user: nur undefined, open, public, password
		$data->{'files'} = [grep {
			$_->{permission_numeric} == UniOrdner::PermissionFile::PERM_OPEN ||
			$_->{permission_numeric} == UniOrdner::PermissionFile::PERM_PUBLIC ||
			$_->{permission_numeric} == UniOrdner::PermissionFile::PERM_PASSWORD ||
			# ACHTUNG: Das hier sollte eigentlihc nicht kommen:
			$_->{permission_numeric} == UniOrdner::PermissionFile::PERM_UNDEFINED
		} @{$data->{'files'}}];
	} else {
		# registered user: auch protected
		$data->{'files'} = [grep { $_->{permission_numeric} != UniOrdner::PermissionFile::PERM_PRIVATE } @{$data->{'files'}}];
	}
}

### data_{yourlabel} functions, as defined in @data_fields.
### called as data_yourlabel($filename, $dirname, \%filestats, $r);
sub data_name { return shift; }
sub data_href {
	my ($fname, $dname) = @_;
	return "$fname/" if(-d "$dname/$fname");
	return $fname;
}
sub data_size {
	my ($fname, $dname, $stats) = @_;
	return format_bytes($stats->{size}); }
sub data_lastmod {
	my ($fname, $dname, $stats) = @_;
	return $stats->{mtime};
	#return strftime "%Y-%b-%d %H:%M:%S", localtime($stats->{mtime});
}
sub data_type {
	my ($fname, $dname, $stats) = @_;
	if(-d "$dname/$fname") {
		return "Directory";
	} else {
		return "File";
	}
}
sub data_is_dir {
	my ($fname, $dname) = @_;
	return -d "$dname/$fname";
}
sub data_permission {
	my ($fname, $dname, $stats, $r) = @_;
	return "later"; # is injected later! (global collect)
}


### private helper functions

sub format_bytes {
	my ($size, $precision) = @_;
	$precision = 0 unless $precision;
	#my @sizes = qw/YB ZB EB PB TB GB MB KB B/;
	my @sizes  = ('Y','Z','E','P','T','G','M','K','&nbsp;'); # short notation
	my $total = @sizes;
	$size /= 1024 while($total-- && $size > 1024);
	return sprintf('%.'.$precision.'f', $size).$sizes[$total];
}


1;
