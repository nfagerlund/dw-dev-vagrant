# dw-dev-vagrant

hi.

## Stuff that might be hosed, won't know until I start another from-scratch build and let it crank for a few hours:

- `apt-get upgrade` does some kind of grub reconfiguration shenanigans in an ncurses interface and it sends your whole terminal session to Extra Hell and scotches the provisioner run.
    - I THINK I might have fixed that with `DEBIAN_FRONTEND=noninteractive` but idk yet.
- `Term::ReadLine::Perl` can't be installed noninteractively because if you pipe `yes` to it it just goes into an infinite loop. I let that damn thing run for like half an hour before I noticed.
    - is this thing really necessary??? or can I just leave it commented out? (this was one of the things that rode along with `Bundle::CPAN`.)

## Stuff that ain't automated yet but I'm sorta workin on it

the non-idempotent setup commands, in order that you're supposed to run em:

- `$LJHOME/bin/checkconfig.pl`
    - this is fucked until https://github.com/dreamwidth/dw-free/pull/2412 or until `List::Util` releases 1.51, lmao
- `$LJHOME/bin/upgrading/update-db.pl -r --innodb`
- `$LJHOME/bin/upgrading/update-db.pl -r --innodb` a second time, for some reason
- `$LJHOME/bin/upgrading/update-db.pl -r --cluster=all --innodb`
- `$LJHOME/bin/upgrading/update-db.pl -p`
- `mysql -u dw -p dw_schwartz < /usr/share/doc/libtheschwartz-perl/schema.sql`
- `$LJHOME/bin/upgrading/make_system.pl`
- `$LJHOME/bin/upgrading/texttool.pl load`
- `$LJHOME/bin/build-static.sh`

networking heck:

- you just can't DW with /etc/hosts. too much subdomain shenanigans.
    - I got dnsmasq figured out tho:
        - http://wiki.dreamwidth.net/wiki/index.php/Subdomain_setup#Local_development_via_dnsmasq
        - https://passingcuriosity.com/2013/dnsmasq-dev-osx/
        - brew install it.
        - config file at `/usr/local/etc/dnsmasq.conf`
            - uncomment `domain-needed` and `bogus-priv`
            - set `listen-address` to the host mac's IP address on the bridged network, plus the loopback address. comma separated.
            - set `address=/dev-width.test/<BOX'S BRIDGED IP>`
                - UGH, which will be different on every run, I wonder if https://github.com/mattes/vagrant-dnsmasq is plausible for handling this.
        - start it with `sudo brew services start dnsmasq` (it'll fail to get a port without the sudo.)
            - it should ask for firewall permissions at this point.
        - create dir `/etc/resolver` if it doesn't exist.
        - create file `/etc/resolver/test`, contents `nameserver 127.0.0.1`. Now host mac will hit dnsmasq for `.test` domains.
        - I was worried this would be hell because mojave, but no, I just forgot my fuckin sudo! we're golden!!

## Stuff where I just got no fuckin clue

- sending email. obviously everyone under the sun is gonna block it, but how do I get it sending to like a local pop3 box if I need to try stuff? this seems totally tractable but is something I've never fussed with before.
- IDK if bridged mode networking is actually good to be using here (spoiler, probably not), but I never did figure out how to master virtualbox's multi-adapter whoopie-cushion tornado. ugh.

