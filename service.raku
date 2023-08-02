use Cro::HTTP::Server;
use Cro::HTTP::Client;
use Cro::HTTP::Router;
use Python2::Compiler::Service;

$*ERR.out-buffer = False;
$*OUT.out-buffer = False;

sub spawn_server (Int $port!) {
    my Cro::Service $service = Cro::HTTP::Server.new:
        :host<localhost>, :port($port), :application(
            route {
                include Python2::Compiler::Service.routes();
            });

    $service.start;
    note "Listening on port $port";

    my $notify-proc = run 'systemd-notify', 'READY=1';
    note "systemd-notify failed with exit code {$notify-proc.exitcode}"
        unless $notify-proc.exitcode == 0;

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
            my $notify-proc = run 'systemd-notify', 'WATCHDOG=1';
            note "systemd-notify failed with exit code {$notify-proc.exitcode}"
                unless $notify-proc.exitcode == 0;
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
