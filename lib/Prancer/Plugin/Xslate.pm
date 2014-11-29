package Prancer::Plugin::Xslate;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '0.990002';

use Prancer::Plugin;
use parent qw(Prancer::Plugin Exporter);

# used to merge config values into the template
use Prancer qw(config);

use Text::Xslate;
use Try::Tiny;
use Carp;

our @EXPORT_OK = qw(render mark_raw unmark_raw html_escape uri_escape);
our %EXPORT_TAGS = ('all' => [ @EXPORT_OK ]);

# even though this *should* work automatically, it was not
our @CARP_NOT = qw(Prancer Try::Tiny);

sub load {
    my $class = shift;
    my $self = bless({}, $class);

    # the config is modified and used every time "render" is called
    $self->{'_config'} = $self->config->remove("template") || {};

    # now export the keyword with a reference to $self
    {
        ## no critic (ProhibitNoStrict ProhibitNoWarnings)
        no strict 'refs';
        no warnings 'redefine';
        *{"${\__PACKAGE__}::render"} = sub {
            return $self->_render(@_);
        };
    }

    return $self;
}

sub path {
    my $self = shift;
    if (@_) {
        $self->{'_config'}->{'path'} ||= [];
        push(@{$self->{'_config'}->{'path'}}, @_);
    }
    return $self->{'_config'}->{'path'};
}

sub add_function {
    my ($self, $key, $value) = @_;

    # $value should be a coderef
    # add $value as a function to the template engine to be called using $key
    $self->{'_config'}->{'function'} ||= {};
    $self->{'_config'}->{'function'}->{$key} = $value;

    return;
}

sub add_module {
    my ($self, $key, $value) = @_;

    # $key should be the name of the module
    # $value should be the what to import, if anything
    $self->{'_config'}->{'module'} ||= [];
    push(@{$self->{'_config'}->{'module'}}, $key, $value || []);

    return;
}

sub _render {
    my ($self, $template, $vars) = @_;

    # just pass all of the options directly to Text::Xslate
    # some default options that are important to remember:
    #    cache     = 1
    #    cache_dir = $ENV{'HOME'}/.xslate_cache
    #    verbose   = 1
    #    suffix    = '.tx'
    #    syntax    = 'Kolon'
    #    type      = 'html' (identical to xml)
    my $tx = Text::Xslate->new(%{$self->{'_config'}});

    # merge configuration values into the template variable list
    my $config = config->get();
    $vars = merge({ 'config' => $config }, $vars);

    return $tx->render($template, $vars);
}

sub mark_raw {
    my $self = ref($_[0]) && $_[0]->isa(__PACKAGE__) ?
        shift : (defined($_[0]) && $_[0] eq __PACKAGE__) ?
        bless({}, shift) : bless({}, __PACKAGE__);
    return Text::Xslate::mark_raw(@_);
}

sub unmark_raw {
    my $self = ref($_[0]) && $_[0]->isa(__PACKAGE__) ?
        shift : (defined($_[0]) && $_[0] eq __PACKAGE__) ?
        bless({}, shift) : bless({}, __PACKAGE__);
    return Text::Xslate::unmark_raw(@_);
}

sub html_escape {
    my $self = ref($_[0]) && $_[0]->isa(__PACKAGE__) ?
        shift : (defined($_[0]) && $_[0] eq __PACKAGE__) ?
        bless({}, shift) : bless({}, __PACKAGE__);
    return Text::Xslate::html_escape(@_);
}

sub uri_escape {
    my $self = ref($_[0]) && $_[0]->isa(__PACKAGE__) ?
        shift : (defined($_[0]) && $_[0] eq __PACKAGE__) ?
        bless({}, shift) : bless({}, __PACKAGE__);
    return Text::Xslate::uri_escape(@_);
}

# stolen from Hash::Merge::Simple
sub merge {
    my ($left, @right) = @_;

    return $left unless @right;
    return merge($left, merge(@right)) if @right > 1;

    my ($right) = @right;
    my %merged = %{$left};

    for my $key (keys %{$right}) {
        my ($hr, $hl) = map { ref($_->{$key}) eq "HASH" } $right, $left;

        if ($hr and $hl) {
            $merged{$key} = merge($left->{$key}, $right->{$key});
        } else {
            $merged{$key} = $right->{$key};
        }
    }

    return \%merged;
}

1;

=head1 NAME

Prancer::Plugin::Xslate

=head1 SYNOPSIS

TODO

=head1 OPTIONS

TODO

=cut
