# dw-dev-vagrant

hi. This brings up a disposable Dreamwidth dev instance, with all required services configured and running (the workers are up, blobstore is configured so you can upload icons, etc.).

- Fork dreamwidth/dw-free.
- Clone this repo.
- Copy `config-example.yaml` to `config.yaml` and edit as needed.
- `vagrant up`
- [Commit whatever DNS Crimes you gotta](#dns) to make sure your normal computer can reach the VM at `dev-width.test` and all subdomains thereof. (It'll print a message with its IP addresses after it's all the way up; use the bridged one on your local network, not the NAT-ted one.)
- Browse to `http://dev-width.test` and log in as "system" (using the password in config.yaml).
- Log into the VM with `vagrant ssh` and switch to the DW user with `sudo -iu dw`. Nothing should require a password, and dw can sudo to restart apache or whatever (`sudo apache2ctl graceful`).
- Have fun!
    - DW code is at `~/dw`, and you should be able to fetch from and push to your fork.
    - I've got ag installed so you can search for stuff. `ag --help` for info.
    - Root disk looks like it's set to 20gb (dynamically allocated), which should hopefully last u long enough to hack on a few things.

## Dealing with Dreamwidth accounts

### Empowering the system user

The system user starts with no permissions except the ability to give anyone any permission. So to do basically anything, you first have to give _yourself_ the necessary permissions. Start with the payments permission, so you can create invite codes for additional scratch users.

- http://www.dev-width.test/admin/priv/

### Making invite codes

Use the admin console.

- http://www.dev-width.test/admin/console

`make_invites <username> <count> <reason>`

### Email

DW accounts need to verify email addresses to do anything fun (like post comments), but your real email provider is DEFINITELY not accepting anything from this suspicious object.

So we have a local mailbox you can use. Just enter `dw@dev-width.post` as the email for all your test accounts. To check that mailbox, log into the VM as the `dw` user (see above) and run `mutt`.

## Stuff that ain't automated yet or is kinda busted but I'm sorta workin on it

### DNS

You have to be able to reach your dev instance with a web browser, but you can't just add it to /etc/hosts because DW uses approximately infinity subdomains. Your main options seem to be:

#### Mac/Linux: dnsmasq.

I got this working. Seems fine.

- [Relevant bit on the DW wiki](http://wiki.dreamwidth.net/wiki/index.php/Subdomain_setup#Local_development_via_dnsmasq)
- [A good post with mac instructions](https://passingcuriosity.com/2013/dnsmasq-dev-osx/)
- brew install it.
- config file at `/usr/local/etc/dnsmasq.conf`
    - uncomment `domain-needed` and `bogus-priv`
    - set `listen-address` to the host mac's IP address on the bridged network, plus the loopback address. comma separated.
    - set `address=/dev-width.test/<BOX'S BRIDGED IP>`
        - UGH, which will be different on every run, I wonder if https://github.com/mattes/vagrant-dnsmasq is plausible for handling this.
- start it with `sudo brew services start dnsmasq` (it'll fail to get a port without the sudo.)
    - it should ask for firewall permissions at this point.
- `sudo mkdir /etc/resolver` if it doesn't exist.
- create file `/etc/resolver/test`, with contents `nameserver 127.0.0.1`. Now the host mac will hit dnsmasq for `.test` domains.

#### Windows: Acrylic?

I don't know anything about this, [but StackOverflow consensus seems bullish on it.](https://stackoverflow.com/questions/138162/wildcards-in-a-windows-hosts-file)

#### iOS: Socks proxy through your Mac

TBH at this point you probably need to actually set up DNS on your local network, but if you just want to test a one-off, I got this working fine without having to install any extra stuff anywhere.

[This brief tutorial had everything I needed.](https://gist.github.com/austinhappel/5614113)

When you're done, remember to set your phone's proxy settings back to "off" and kill the SSH forwarding process on your Mac. (It stays foregrounded in your terminal, so at least you're not likely to forget it and leave it running.)

## Stuff that might be hosed, won't know until I start another from-scratch build and let it crank for a few hours:

- `Term::ReadLine::Perl` can't be installed noninteractively because if you pipe `yes` to it it just goes into an infinite loop. I let that damn thing run for like half an hour before I noticed.
    - is this thing really necessary??? or can I just leave it commented out? (this was one of the things that rode along with `Bundle::CPAN`.)
- the DB/asset-compile setup scripts should work now, but I've never tested em.
- need to double-check that gearman is running correctly.

## Improving this dev setup

good gracious, please do.

[these are the instructions I'm automating.](http://wiki.dwscoalition.org/wiki/index.php/Dreamwidth_Scratch_Installation) They're missing some bits (uncommenting the blob store stuff is basically mandatory, and it doesn't tell you about gearman).

when iterating more quickly, the command you need for refreshing is `vagrant provision --provision-with puppet`

All the Puppet modules are just vendored because I'm lazy and I assume you are too. `dw_dev` is the only unique one.

IDK if bridged mode networking is actually good to be using here (spoiler, probably not), but I never did figure out how to master virtualbox's multi-adapter whoopie-cushion tornado. ugh. Maybe later.

## License(s)

- Like I said, I vendored a lot of Puppet modules, so I guess I'm accidentally a distro now. They all ride under the terms of their original licenses, which are vendored right along with em. Mostly Apache 2, small GPL contingent, one Perl Artistic.
- The stuff I wrote is all in the dw_dev module, which I'm making available under the Apache 2 licence.
