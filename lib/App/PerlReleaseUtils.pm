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
        include_latest_versions => {
            summary => "Only include latest N version(s) of each dist",
            schema => 'posint*',
        },
        exclude_latest_versions => {
            summary => "Exclude latest N version(s) of each dist",
            schema => 'posint*',
        },
        include_dev_release => {
            schema => 'bool*',
            default => 1,
        },
        include_nondev_release => {
            schema => 'bool*',
            default => 1,
        },
    },
    args_rels => {
        choose_one => [qw/include_latest_versions exclude_latest_versions/],
    },
};
sub grep_perl_release {
    require Regexp::Pattern::Perl::Release;

    # XXX schema
    my %args = @_;
    $args{include_dev_release} //= 1;
    $args{include_nondev_release} //= 1;

    my $re = qr/\A(?:$Regexp::Pattern::Perl::Release::RE{perl_release_archive_filename}{pat})\z/;

    my @rels;
    my %dists;
    while (defined(my $line = <>)) {
        chomp $line;
        unless ($line =~ $re) {
            log_trace "Line excluded (not a perl release archive filename): $line";
            next;
        }
        my $rec = {
            release => $line,
            dist => $1,
            version0 => $2,
        };
        ($rec->{version} = $rec->{version0}) =~ s/-TRIAL/_001/;
        #log_trace "D:version=<%s>", $rec->{version};
        eval { $rec->{version_parsed} = version->parse($rec->{version}) };
        if ($@) {
            log_warn "Release %s: Can't parse version %s: %s, skipping this release", $line, $rec->{version}, $@;
            next;
        }
        $rec->{is_dev} = $rec->{version} =~ /_/ ? 1:0;

        if ($rec->{is_dev} && !$args{include_dev_release}) {
            log_trace "Line excluded (excluding dev perl release): $line";
            next;
        }
        if (!$rec->{is_dev} && !$args{include_nondev_release}) {
            log_trace "Line excluded (excluding non-dev perl release): $line";
            next;
        }

        $dists{ $rec->{dist} } //= [];
        push @rels, $rec;
        push @{ $dists{ $rec->{dist} } }, $rec;
    }

    if (defined($args{include_latest_versions}) || defined($args{exclude_latest_versions})) {
        my @res;
      DIST:
        for my $dist (keys %dists) {
          FILTER: {
                if (defined $args{include_latest_versions}) {
                    if (@{ $dists{$dist} } <= $args{include_latest_versions}) {
                        last FILTER;
                    }
                } elsif (defined $args{exclude_latest_versions}) {
                    if (@{ $dists{$dist} } <= $args{exclude_latest_versions}) {
                        last FILTER;
                    }
                }

                # sort each dist by version
                $dists{$dist} = [ sort {$a->{version_parsed} <=> $b->{version_parsed}} @{ $dists{$dist} } ];

                # only keep n latest versions
                if (defined $args{include_latest_versions}) {
                    my @removed = splice @{ $dists{$dist} }, 0, @{ $dists{$dist} } - $args{include_latest_versions};
                    log_trace "Excluding old releases of dist %s: %s", $dist, [map {$_->{release}} @removed];
                    # exclude n latest versions
                } elsif (defined $args{exclude_latest_versions}) {
                    my @removed = splice @{ $dists{$dist} }, @{ $dists{$dist} } - $args{exclude_latest_versions};
                    log_trace "Excluding latest releases of dist %s: %s", $dist, [map {$_->{release}} @removed];
                }
            } # FILTER
            push @res, map { $_->{release} } @{ $dists{$dist} };
        }
        return [200, "OK", \@res];

    } else {
        return [200, "OK", [map { $_->{release} } @rels]];
    }
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
