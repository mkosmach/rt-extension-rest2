package RT::Extension::REST2::Resource::Collection::QueryByJSON;
use strict;
use warnings;

use Moose::Role;
use namespace::autoclean;

use JSON ();

with (
    'RT::Extension::REST2::Resource::Collection::ProcessPOSTasGET',
    'RT::Extension::REST2::Resource::Role::RequestBodyIsJSON'
         => { type => 'ARRAY' },
);

requires 'collection';

has 'query' => (
    is          => 'ro',
    isa         => 'ArrayRef[HashRef]',
    required    => 1,
    lazy_build  => 1,
);

sub _build_query {
    my $self = shift;
    my $content = $self->request->method eq 'GET'
                ? $self->request->param('query')
                : $self->request->content;
    return $content ? JSON::decode_json($content) : [];
}

sub allowed_methods {
    [ 'GET', 'POST' ]
}

sub searchable_fields {
    $_[0]->collection->RecordClass->ReadableAttributes
}

sub limit_collection {
    my $self        = shift;
    my $collection  = $self->collection;
    my $query       = $self->query;
    my @fields      = $self->searchable_fields;
    my %searchable  = map {; $_ => 1 } @fields;

    for my $limit (@$query) {
        next unless $limit->{field}
                and $searchable{$limit->{field}}
                and defined $limit->{value};

        $collection->Limit(
            FIELD       => $limit->{field},
            VALUE       => $limit->{value},
            ( $limit->{operator}
                ? (OPERATOR => $limit->{operator})
                : () ),
            CASESENSITIVE => ($limit->{case_sensitive} || 0),
        );
    }
    return 1;
}

1;
