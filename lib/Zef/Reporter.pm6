use v6;
use Zef;

class Zef::Reporter does Messenger does Reporter {
    method probe {
        state $probe = (try require Net::HTTP::POST) !~~ Nil ?? True !! False;
        ?$probe;
    }

    method report($event) {
        once { say "!!!> Install Net::HTTP to enable p6c test reporting" unless self.probe }

        if self.probe {
            try require Net::HTTP::POST;
            my $candi := $event.<payload>;
            my $response = ::('Net::HTTP::POST')("http://testers.perl6.org/report", body => to-json({
                :name($candi.dist.name),
                :version(first *.defined, $candi.dist.meta<ver version>),
                :dependencies($candi.dist.meta<depends>),
                :metainfo($candi.dist.meta.hash),
                :build-output(Str),
                :build-passed(True),
                :test-output($candi.test-results.Str),
                :test-passed(so $candi.test-results.map(*.so).all),
                :distro({
                    :name($*DISTRO.name),
                    :version($*DISTRO.version.Str),
                    :auth($*DISTRO.auth),
                    :release($*DISTRO.release),
                }),
                :kernel({
                    :name($*KERNEL.name),
                    :version($*KERNEL.version.Str),
                    :auth($*KERNEL.auth),
                    :release($*KERNEL.release),
                    :hardware($*KERNEL.hardware),
                    :arch($*KERNEL.arch),
                    :bits($*KERNEL.bits),
                }),
                :perl({
                    :name($*PERL.name),
                    :version($*PERL.version.Str),
                    :auth($*PERL.auth),
                    :compiler({
                        :name($*PERL.compiler.name),
                        :version($*PERL.compiler.version.Str),
                        :auth($*PERL.compiler.auth),
                        :release($*PERL.compiler.release),
                        :build-date($*PERL.compiler.build-date.Str),
                        :codename($*PERL.compiler.codename),
                    }),
                }),
                :vm({
                    :name($*VM.name),
                    :version($*VM.version.Str),
                    :auth($*VM.auth),
                    :config($*VM.config),
                    :properties($*VM.?properties),
                    :precomp-ext($*VM.precomp-ext),
                    :precomp-target($*VM.precomp-target),
                    :prefix($*VM.prefix.Str),
                }),
            }).encode );

            return $response.content(:force);
        }
    }
}

=begin pod

=head1 NAME

Zef::Reporter - blah blah blah

=head1 SYNOPSIS

  use Zef::Reporter;

=head1 DESCRIPTION

Zef::Reporter is ...

=head1 AUTHOR

Breno G. de Oliveira <garu@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Breno G. de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
