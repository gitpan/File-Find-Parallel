package File::Find::Parallel;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv( '0.0.1' );

sub new {
    my $class = shift;
    my $self = bless { dirs => [], }, ref $class || $class;
    $self->add_dirs( @_ );
    return $self;
}

sub set_dirs {
    my $self = shift;
    $self->{dirs} = [@_];
}

sub get_dirs {
    my $self = shift;
    return @{ $self->{dirs} };
}

sub add_dirs {
    my $self = shift;
    push @{ $self->{dirs} }, @_;
}

sub _iterator {
    my $self      = shift;
    my $threshold = shift;

    my @dirs = $self->get_dirs;
    my @work = @dirs ? ( '.' ) : ();

    return sub {
        return unless @work;
        my $rel = File::Spec->canonpath( shift @work );
        my %got = ();
        for my $base ( @dirs ) {
            my $abs = File::Spec->catdir( $base, $rel );
            if ( -d $abs ) {
                if ( opendir my $dh, $abs ) {
                    $got{$_}++ for grep { $_ !~ /^[.][.]?$/ } readdir $dh;
                    close $dh;
                }
                else {
                    carp "Can't read $abs ($!)";
                }
            }
        }
        push @work, map { File::Spec->catdir( $rel, $_ ) }
          sort grep { $got{$_} >= $threshold } keys %got;
        return $rel;
    };
}

sub all_iterator {
    my $self = shift;
    return $self->_iterator( scalar $self->get_dirs );
}

sub any_iterator {
    my $self = shift;
    return $self->_iterator( 1 );
}

1;
__END__

=head1 NAME

File::Find::Parallel - Traverse a number of similar directories in parallel

=head1 VERSION

This document describes File::Find::Parallel version 0.0.1

=head1 SYNOPSIS

    use File::Find::Parallel;

    my $ffp = File::Find::Parallel->new( qw( /foo /bar ) );

    print "Union:\n";
    my $union = $ffp->any_iterator
    print "  $_\n" while $_ = $union->();

    print "Intersection:\n";
    my $inter = $ffp->all_iterator
    print "  $_\n" while $_ = $inter->();

=head1 DESCRIPTION

L<File::Find> is the ideal tool for quickly scanning a single directory.
But sometimes it's nice to be able to perform operations on multiple
similar directories in parallel. Perhaps you need to compare the
contents of two directories or convert files that are shared in more
than one directory into hard links.

This module manufactures iterators that visit each file and directory in
either the union or the intersection of a number of directories. Hmm.
What does that mean?

Given two directory trees like this

    foo
    foo/a
    foo/b/c
    foo/d

    bar
    bar/a
    bar/b
    bar/e

you can choose to work with the intersection of the two directory
structures:

    .
    ./a
    ./b

That is the subdirectories and files that the F<foo> and F<bar> share.

Alternately you can work with the union of the two directory structures:

    .
    ./a
    ./b
    ./b/c
    ./d
    ./e

Still not clear? Well, if you wanted to do a recursive diff on the two
directories you'd iterate their union so you could report files that
were present in F<foo> but missing from F<bar> and vice-versa.

If, on the other hand you wanted to scan the directories and make any
files shared in both into hard links you'd iterate their intersection:
there's no potential for hard linking items that exist in only one
directory.

File::Find::Parallel can scan any number of directories at the same
time. Here's an example (on Unix systems) that returns the list of all
files and directories that are contained in all home directories.

    use File::Glob ':glob';
    use File::Find::Parallel;

    my $find = File::Find::Parallel->new( bsd_glob( '/home/*' ) );

    my @common = ( );
    my $iter = $find->all_iterator;
    while ( defined my $obj = $iter->() ) {
        push @common, $obj;
    }

    print "The following files are common to ",
          "all directories below /home :\n";

    print "    $_\n" for @common;

=head1 INTERFACE

=over

=item C<< new >>

Create a new File::Find::Parallel. You may optionally pass a list of
directories to scan.

=item C<< set_dirs( @dirs ) >>

Set the list of directories to be scanned. Any number of directories may
be scanned. If you are scanning just a single directory consider using
L<File::Find> instead.

=item C<< get_dirs >>

Get the list of directories to be scanned.

    my @dirs_to_scan = $ffp->get_dirs;

=item C<< add_dirs >>

Add to the list of directories to be scanned.

    $ffp->add_dirs( 'a' );
    $ffp->add_dirs( 'b', 'c' );

=item C<< any_iterator >>

Get an iterator that will return the names of all the files and
directories that are in the union of the directories to be scanned.

The returned iterator is a code reference that returns a new name each
time it is called. It returns undef when all names have been returned.

The returned names are relative to the base directories. Given
directories like this

    foo             bar
    foo/a           bar/a
    foo/b/c         bar/d/e

the iterator would return

    .
    a
    b
    d
    b/c
    d/e

That is it returns the list of names that would result if F<foo> was
copied over F<bar> and then F<bar> scanned.

Directories are searched in breadth first order.

=item C<< all_iterator >>

Get an iterator that will return the names of all the files and
directories that are in the intersection of the directories to be
scanned.

Given directories like this

    foo             bar
    foo/a           bar/a
    foo/b/c         bar/d/e

the iterator would return

    .
    a

That is it returns the names of those files and directories that can be
found in both F<foo> and F<bar>.

=back

Create a new C<< File::Find::Parallel >>.

=head1 DEPENDENCIES

The tests require L<File::Tempdir>.

=head1 BUGS AND LIMITATIONS

I haven't checked but it must be slower than L<File::Find>. Use that
instead if you only want to scan a single directory at a time.

Please report any bugs or feature requests to
C<bug-file-find-parallel@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
