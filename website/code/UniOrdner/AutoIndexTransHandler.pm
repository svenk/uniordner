package UniOrdner::AutoIndexTransHandler;

use UniOrdner::AutoIndex;

use Apache2::Module; # get_config
use Apache2::Const qw(:common :types);
use Apache2::Log;
use Apache2::URI;
use Apache2::RequestIO;
use Apache2::RequestRec; # path_info, finfo
use Apache2::SubRequest; # lookup_uri
use APR::Finfo ();

use Data::Dumper;

sub handler {
	# transhandler for correct index file handling
	my $r = shift;
	
	print STDERR "Verfuckter Idiot, mit ", Dumper($r->content_type), " nicht ", Dumper($r->content_type eq Apache2::Const::DIR_MAGIC_TYPE)," und ",$r->uri, "\n";
	
	# Only handle directories
	return Apache2::Const::DECLINED unless $r->uri =~ /\/$/;
	return Apache2::Const::DECLINED unless $r->content_type &&
			$r->content_type eq Apache2::Const::DIR_MAGIC_TYPE;

	print STDERR "Going on!\n";
			
	# config holen geht nicht weils nicht von unserem Modul ist.
	#my $cfg = Apache2::Module::get_config(__PACKAGE__, $r->server, $r->per_dir_config);
	#print Dumper($cfg);
	foreach (@UniOrdner::AutoIndex::indexfiles) {
		print STDERR "Trying $_ below ", $r->uri,"\n";
		my $subr = $r->lookup_uri($r->uri . $_);
		#print STDERR "Running, got ", $subr->run,"\n";
		if($subr->path_info) {
			print STDERR "Has path info: ",$subr->path_info,"\n";
			last;
		}
		if (stat $subr->finfo){
			print STDERR "Got $_\n!!";
			$r->uri($subr->uri);
			last;
		} else {
			print STDERR "Has no stat\n";
		}
		print STDERR "No luck with $_\n";
	}
	return Apache2::Const::DECLINED;
}

1;