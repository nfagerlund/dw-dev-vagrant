# cpanm

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with cpanm](#setup)
    * [What cpanm affects](#what-cpanm-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with cpanm](#beginning-with-cpanm)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
    * [Known Issues](#known-issues)
1. [Development - Guide for contributing to the module](#development)

## Description

The cpanm module manages CPAN packages using the cpanminus package. It exists
to provide a simple way to install CPAN modules with the option to not run test
suites.  The intent is that it should work with Debianish and Redhatty
distributions.

The module provides a class `cpanm` which will install Perl components, gcc,
make and cpanminus itself. It also provides a resource type `cpanm` which you
can use to manage modules in more or less the same way as `package` works.

## Setup

### What cpanm affects

This module will currently automatically install the following packages:
* perl
* gcc
* make
* perl-core on RHEL6-7

This might cause conflicts if you include them elsewhere.

### Setup Requirements

This module contains a custom type, so you must make sure pluginsync is enabled
if you are using a puppet master.

### Beginning with cpanm

```
include cpanm

cpanm {'CGI':
  ensure => latest,
}
```

## Usage

The `cpanm` resource supports additional parameters, `test` and `force`, to
enable CPAN tests and force CPAN installation respectively.

## Reference

The `cpanm` class currently supports one parameter:

* `mirror`
  A CPAN mirror to use to retrieve App::cpanminus. This is passed to
  `cpanm` as `--from`, meaning that only this mirror will be used.

The `cpanm` resource supports:

* `ensure`
  absent, present or latest.

* `force`
  Pass the '-f' (force) option to  CPAN installation. Boolean, default is false.
  This only has an effect on installation or upgrade. It does nothing unless
  the value of `ensure` causes a change to be made.

* `mirror`
  A CPAN mirror to use to retrieve packages. This is passed to
  `cpanm` as `--from`, meaning that only this mirror will be used.

* `test`
  Run CPAN tests. Boolean, default is false.

The module contains a copy of cpanminus, which is used to bootstrap installing itself.

## Limitations

The module is tested on RHEL 5-7 and Debian Jessie. It should work properly in
those environments, but it is relatively simple, so it may well work in similar
environments without modification. If you need specific changes for your
environment, feel free to send them!

### Known Issues

The listing of installed CPAN modules is based on `perldoc perllocal`. This
generally works well, but doesn't get updated when you remove a CPAN module.

## Development

If you make improvements or fixes, please feel free to send a PR on Github.
This module exists to solve a specific problem for me, but I'm quite happy to
extend it to support other people's use cases.

## Contributors

This module contains a copy of cpanminus retrieved from https://cpanmin.us.
[App::cpanminus](http://search.cpan.org/~miyagawa/App-cpanminus-1.7042/lib/App/cpanminus.pm)
is written by Tatsuhiko Miyagawa and distributed under the same terms as Perl.
You can read more details about contributors via the link.
