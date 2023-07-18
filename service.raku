use Cro::HTTP::Server;
use Cro::HTTP::Client;
use Cro::HTTP::Router;
use Python2::Compiler::Service;

sub spawn_server (Int $port!) {
    my Cro::Service $service = Cro::HTTP::Server.new:
        :host<localhost>, :port($port), :application(
            route {
                include Python2::Compiler::Service.routes();
            });

    $service.start;
    note "Listening on port $port";

    return $service;
}

sub spawn_watchdog (Int $port!) {
    my $watchdog = Supply.interval(10);
    $watchdog.tap({
        my $resp = await Cro::HTTP::Client.post: 'http://localhost:' ~ $port ~ '/compile',
            content-type => 'application/json',
            body => {
                code     => '1',
                embedded => 'watchdog',
                type     => 'expression',
            };


        my $response = await $resp.body;
        if ($response ~~ /Python2/) {
            my $proc = run('/bin/systemd-notify', 'WATCHDOG=1');
        }
    });
}

multi sub MAIN (
    Int  :$port = 27099,
    Bool :$watchdog = False,
) {
    my $service = spawn_server($port);
    if $watchdog {
        note 'systemd watchdog enabled';
        spawn_watchdog($port);
    }

    react whenever signal(SIGINT)  { $service.stop; exit; }
}
