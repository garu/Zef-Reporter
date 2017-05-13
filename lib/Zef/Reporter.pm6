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
            my $response = ::('Net::HTTP::POST')("http://api.cpantesters.org/v3/report", body => to-json({
                :reporter({
                    :email( $*HOME.child(q|.cpanreporter/config.ini|).lines>>.split("=").grep( *[0] eq "email_from" ).map( *[1] )[0] )
                }),
                :environment({
                    :user_agent( $?PACKAGE ~ ' ' ~ $?PACKAGE.^ver ),
                    :language({
                        :name<Perl 6>,
                        :implementation($*PERL.compiler.name)
                        :version($*PERL.compiler.version.Str),
                        :backend({
                            :engine($*VM.name),
                            :version($*VM.version.Str)
                        }),
                        :archname( join('-', $*KERNEL.hardware, $*KERNEL.name) ),
                        :variables({
                            '$*REPO.repo-chain' => $*REPO.repo-chain,
                        }),
                        # TODO include critical distributions that are bundled
                        # to either rakudo or zef. Right now I'm not sure what's
                        # the best way to achieve this. The versions below should
                        # be the versions that were used to test/install the dist.
                        # :toolchain({
                        #    'zef' => version
                        #    'TAP' => version
                        # }),
                        # TODO include build output string, if available.
                        # :build(Str),
                    }),
                    :system({
                        :osname($*KERNEL.name),
                        :osversion($*KERNEL.version.Str),
                        :variables({
                            :PATH(%*ENV<PATH>.Str),
                            %*ENV.grep( *.key.starts-with("PERL" | "RAKUDO") ),
                        }),

                        # TODO add those once they become available:
                        # :hostname(Str),        # hostname
                        # :cpu_count(Str),       # how many CPUs and cores do we have
                        # :cpu_type(Str),        # e.g. 'Intel Core i5'
                        # :cpu_description(Str), # e.g. 'MacBook Air (1.3 GHz)
                        # :filesystem(Str),      # FS where dist was tested
                    }),
                }),
                :result({
                    :grade(so $candi.test-results.map(*.so).all ?? 'PASS' !! 'FAIL' ),
                    :output({
                        :configure( $candi.^find_method('configure-results') ?? $candi.configure-results.Str !! Str ),
                        :build( $candi.^find_method('build-results') ?? $candi.build-results.Str !! Str ),
                        :test( $candi.^find_method('test-results') ?? $candi.test-results.Str !! Str ),
                        :install( $candi.^find_method('install-results') ?? $candi.install-results.Str !! Str ),
                    }),

                    # TODO we'd love to send:
                    # :tests(Int),    # number of tests that ran (tests, not test files)
                    # :failures(Int), # how many test failures
                    # :skipped(Int),  # how many tests were skipped
                    # :todo({
                    #    :pass(Int), # how many tests marked as TODO have passed
                    #    :fail(Int), # how many tests marked as TODO have failed
                    # }),
                    # :warnings(Int), # did we get any warnings? If so, how many?
                    # :duration(Int), # how long did it take us to run the tests, in seconds
                }),
                :distribution({
                    :name($candi.dist.name),
                    :version(first *.defined, $candi.dist.meta<ver version>),

                    # TODO we'd love to traverse through
                    # $candi.dist.meta<depends> and turn it into (expected JSON):
                    # [
                    #   { "phase": "test", "name": "Some::Dist", "need": "0.1", "have": "3.2" },
                    #   { "phase": "build", "name": "Other::Dist", "need": "1.23", "have": "1.77" },
                    # ]
                }),
            }).encode);

            return $response.content(:force);
        }
    }
}

=begin pod

=head1 NAME

Zef::Reporter - send Perl 6 reports to CPAN Testers (using zef)

=head1 DESCRIPTION

Zef::Reporter is a module to send installation success/failure reports to CPAN Testers.

=head1 AUTHORS

Breno G. de Oliveira (GARU)
Nick Logan (UGEXE)

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Breno G. de Oliveira, Nick Logan

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
