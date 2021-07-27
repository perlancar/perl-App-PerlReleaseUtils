package App::PerlReleaseUtils;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

#our %argspec0_release = (
#    dist => {
#        schema => 'perl::relname*',
#        req => 1,
#        pos => 0,
#        completion => sub {
#            require Complete::Dist;
#            my %args = @_;
#            Complete::Dist::complete_dist(word=>$args{word});
#        },
#    },
#);

$SPEC{grep_perl_release} = {
    v => 1.1,
    args => {
        include_dist_latest => {
            schema => 'posint*',
        },
    },
};
sub grep_perl_release {
    require Regexp::Pattern::Perl::Release;

    my %args = @_;

    my $re = qr/\A(?:$Regexp::Pattern::Perl::Release::RE{perl_release_archive_filename})\z/;

    my %rels;
    my %dists;
    while (<>) {
        chomp;
        next unless $re;
        $dists{ $1 } //= [];
        push @{ $dists{ $1 } }, $_;
    }

    [200, "OK", \%dists];
}

1;
# ABSTRACT: Collection of utilities related to Perl distribution releases

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to Perl
distribution releases:

#INSERT_EXECS_LIST


=head1 FAQ

#INSERT_BLOCK: App::PMUtils faq


=head1 SEE ALSO

#INSERT_BLOCK: App::PMUtils see_also

=cut
