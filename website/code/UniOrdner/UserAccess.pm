package UniOrdner::UserAccess;

use strict;
use warnings;

use UniOrdner::PermissionFile;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
	level => $DEBUG,
	file => ">> /tmp/access.log"
});

use File::Spec;
use APR::Table;
use Apache2::RequestUtil ();
use Apache2::Reload;
use Apache2::Access ();
use Apache2::RequestRec ();
use Apache2::Connection ();
use Data::Dumper;
  
use Apache2::Const -compile => qw(FORBIDDEN OK HTTP_UNAUTHORIZED HTTP_INTERNAL_SERVER_ERROR DECLINED);

sub handler {
	my $r = shift;
	DEBUG("Accessing ".$r->uri." = ".$r->filename);

	my $perm = UniOrdner::PermissionFile->quick_check_permission($r->filename, $r->dir_config->get('uniroot'));
	DEBUG("Permission = ".UniOrdner::PermissionFile->printable_access($perm));
	
	if( (defined $r->args && $r->args eq 'force-login' && $perm != UniOrdner::PermissionFile::ACCESS_FORBIDDEN)
	    || $perm == UniOrdner::PermissionFile::ACCESS_PASSWORD) {
		$r->add_config(['require valid-user']);
	} elsif($perm == UniOrdner::PermissionFile::ACCESS_OK) {
		return Apache2::Const::OK;
	} elsif($perm == UniOrdner::PermissionFile::ACCESS_FORBIDDEN) {
		return Apache2::Const::FORBIDDEN;
	}
}

1;
