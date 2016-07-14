package UniOrdner::ReadmeFile;

use strict;
use warnings;

use File::Slurp qw( slurp ); # ubuntu: apt-get install libfile-slurp-perl
use Text::Markdown 'markdown'; # apt-get install libtext-markdown-perl

sub get_markdown_readme_file {
	my $this = shift;
	my $readme_file = shift;
	my $content = slurp($readme_file); # make sure of scalar context for slurp!
	$content = markdown($content);
	
	# markdown erkennt keine URLs :(
	$content =~ s#\b(([\w-]+://?|www[.])[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))#<a href="$1">$1</a>#gi;

	return $content;
}

sub get_plain_readme_file {
	my $this = shift;
	my $readme_file = shift;
	my $content = slurp($readme_file);
	
	# replacemenets:
	# the markdown URL regex (john gruber, fireball):
	$content =~ s#\b(([\w-]+://?|www[.])[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))#<a href="$1">$1</a>#gi;
	return $content;
}

1;
