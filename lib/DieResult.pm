use 5.036;
use utf8;
use warnings 'all';
use autodie ':all';
use open qw/:std :utf8/;
utf8::decode($_) for @ARGV;

use Class::Struct 'DieResult' => [
    tag => '$', # 'ok' or 'err'
    data => '$',
];

package DieResult {
    use DieResult::Error;
    use Keyword::Simple;
    use Text::Balanced qw/extract_codeblock/;

    sub import {
        Keyword::Simple::define wrap => sub ($ref) {
            my ($block, $remains) = extract_codeblock($$ref);

            $$ref = <<EOF;
do { no warnings 'misc'; my \$__dieresult_data = [ eval $block ]; if (my \$__dieresult_err = \$@) { DieResult->new( tag => 'err', data => DieResult::Error->new( cause => \$__dieresult_err, position => DieResult::Error::get_position(),),); } else { DieResult->new( tag => 'ok', data => \$__dieresult_data,); } }
$remains
EOF
        };
    }

    sub unimport {
        Keyword::Simple::undefine 'wrap';
    }

    sub is_ok ($self) {
        $self->tag eq 'ok';
    }

    sub is_err ($self) {
        $self->tag eq 'err';
    }

    sub attach ($self, @attachment) {
        if ($self->is_err) {
            $self->data->attach(@attachment);
        }
        $self;
    }

    sub context ($self, $context) {
        if ($self->is_err) {
            $self->data->context($context);
        }
        $self;
    }

    sub unwrap_err ($self) {
        if ($self->is_ok) {
            die 'failed to unwrap err: is not err';
        } else {
            return $self->data;
        }
    }

    sub unwrap ($self) {
        if ($self->is_ok) {
            return @{ $self->data };
        } else {
            die $self->data;
        }
    }

    sub unwrap_or_else ($self, $else) {
        if ($self->is_ok) {
            return @{ $self->data };
        } else {
            return $else->($self->data);
        }
    }
};

1;

=head1 NAME

DieResult - The great new DieResult!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use DieResult;

    my $foo = DieResult->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

jyi2ya, C<< <jyi2ya at qq.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dieresult at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=DieResult>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DieResult


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=DieResult>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/DieResult>

=item * Search CPAN

L<https://metacpan.org/release/DieResult>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by jyi2ya.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007


=cut

1; # End of DieResult
