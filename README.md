# dw-dev-vagrant

hi.

[these are the instructions I'm automating.](http://wiki.dwscoalition.org/wiki/index.php/Dreamwidth_Scratch_Installation)

when iterating more quickly, the command you need for refreshing is `vagrant provision --provision-with puppet`

Wanna log in as the dw user to muck around with code and run scripts? `vagrant ssh` and then `sudo -iu dw`. nothing should require a password, and dw can sudo to restart apache or what have u.

I've got ag installed so you can search for stuff. `ag --help` for info.

there's a git config in there to keep me from going bonkers. mess with it as needed.

I'm using the old puppetlabs vagrant box and it looks like its root disk is set at 20gb (dynamically allocated), which should hopefully last u long enough to hack on a few things before it needs to be retired.

## Stuff that might be hosed, won't know until I start another from-scratch build and let it crank for a few hours:

- `apt-get upgrade` does some kind of grub reconfiguration shenanigans in an ncurses interface and it sends your whole terminal session to Extra Hell and scotches the provisioner run.
    - I THINK I might have fixed that with `DEBIAN_FRONTEND=noninteractive` but idk yet.
- `Term::ReadLine::Perl` can't be installed noninteractively because if you pipe `yes` to it it just goes into an infinite loop. I let that damn thing run for like half an hour before I noticed.
    - is this thing really necessary??? or can I just leave it commented out? (this was one of the things that rode along with `Bundle::CPAN`.)
- the DB/asset-compile setup scripts should work now, but I've never tested em.
- need to double-check that gearman is running correctly.

## Stuff that's just manual because it's part of the application and that's life

- system user has no permissions except the ability to give anyone any permission. so to make invite codes to create a second user, you first have to give yourself the payments permission.
    - http://www.dev-width.test/admin/priv/
- system user doesn't have an email set up so probably can't comment on posts or do some other stuff.
    - just set up an email and verify it
    - but the only email address that works by default is dw@dev-width.post.
        - or I guess vagrant@dev-width.post if you want to be a complete deviant. feel free to create more OS user accounts if you want, but it's easier to just use the same email for all your fake users.
        - see "email heck" below.
    - to check your mail, ssh in, `sudo -iu dw`, and then run `mutt`.
        - arrow keys, enter, q. theoretically you can do cool stuff with mutt, but uhhhhhh seems hard.
        - depending on your terminal you might be able to cmd-click URLs to open them in your desktop browser; at least iterm2 does that, and they probably learned it from WATCHING YOU, DAD.

## Stuff that ain't automated yet or is kinda busted but I'm sorta workin on it

### networking heck:

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

- IDK if bridged mode networking is actually good to be using here (spoiler, probably not), but I never did figure out how to master virtualbox's multi-adapter whoopie-cushion tornado. ugh. Maybe later.

## Appendix: Stuff where I got it figured out but I don't want to delete my angry WIP notes about it yet

### email heck:

- You need to confirm an email address before your test users can post comments.
- there is no way in hell that your shitbox VM on a centurylink dynamic IP is successfully sending anything to your gmail this century.
- you cannot configure dw to use the kind of smtp server you probably have access to, don't bother looking into it.
- guess you could just get multiple things configured properly on your home network and email your fridge or something.
- But the _correctly stupid_ approach is to just email localhost and check the mailbox with mutt!
- Except that dw won't let you set an email that's on its own domain name, since it sometimes uses those for a paid feature.
- So the move is to use a _second_ domain name that resolves to the same host.
- but, dw doesn't consider user@rando.test to be an acceptable email address, and .test is the best practice for throwaway dev domains.
    - This is controlled by `dw_free/htdocs/inc/tlds`, and you can edit that to allow .test domains.
    - But, I haven't found a way to override that in a persistent way that can survive checking out a new branch. Maybe there is one, idk yet.
- anyway, this is why trying to be lawful good always gets you into trouble, fuck that. let's just pick a technically unsafe but rather unlikely legal TLD for our mail alias.
- IIRC no one cool ever gets to have a .post domain, so dev-width.post it is.
