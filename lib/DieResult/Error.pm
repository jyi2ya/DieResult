#!/usr/bin/env perl
use 5.036;
use utf8;
use warnings 'all';
use autodie ':all';
use open qw/:std :utf8/;
utf8::decode($_) for @ARGV;

use Class::Struct 'DieResult::Error' => [
    cause => '$',
    position => '@',
    context => '$',
    attachment => '@',
];

package DieResult::Error {
    use Class::Struct 'DieResult::Error::Collection' => [
        inner => '$',
    ];

    package DieResult::Error::Collection {
        sub add ($self, @errors) {
            push @{ $self->inner->cause }, @errors;
            $self;
        }

        sub attach ($self, @attachment) {
            push @{ $self->inner->attachment }, @attachment;
            $self
        }

        sub context ($self, $context) {
            $self->inner->context($context);
            $self
        }
    };

    use overload '""' => \&stringify;

    sub get_position {
        my (undef, $file, $line, $func) = caller(1);
        (undef, undef, undef, $func) = caller(2);
        [ $file, $line, $func ];
    }

    sub collection {
        DieResult::Error::Collection->new(
            inner => DieResult::Error->new(
                cause => [],
                position => DieResult::Error::get_position,
            )
        );
    }

    sub attach ($self, @attachment) {
        push @{ $self->attachment }, @attachment;
    }

    sub render_leaf ($error) {
        my $text = "$error";
        chomp $text;
        "* $text";
    }

    sub render_block ($self) {
        my ($filename, $line, $func) = @{ $self->position };
        my $context = $self->context;
        my @attachment = @{ $self->attachment };

        my @result;
        push @result, $context if $context;
        push @result, "$func $filename:$line";
        push @result, map { "+ $_" } @attachment;

        my $head = shift @result;
        "* $head", map { "| $_" } @result;
    }

    sub render_collection ($collection) {
        my @collection = @{ $collection->inner->cause };
        my @lines = map {
            my ($first, @lines) = $_->render;
            '| ', "|-$first", map { "| $_" } @lines
        } @collection;
        shift @lines;
        @lines;
    }

    sub render ($self) {
        my @block = $self->render_block;
        my $cause = $self->cause;

        my @cause_block = do {
            if (ref $cause eq 'DieResult::Error') {
                $cause->render;
            } elsif (ref $cause eq 'DieResult::Error::Collection') {
                render_collection($cause);
            } else {
                render_leaf($cause);
            }
        };

        @block, '|', @cause_block;
    }

    sub stringify {
        my $self = shift;
        join "\n", $self->render;
    }
};

1;
