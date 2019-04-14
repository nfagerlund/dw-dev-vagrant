require 'spec_helper'
describe 'cpanm' do
  context 'on Debian with default parameters' do
    let(:facts) { {
      :osfamily => "Debian",
      :operatingsystemmajrelease => "8"
    } }
    it { should contain_class('cpanm') }
    it { should contain_package('perl') }
    it { should contain_package('gcc') }
    it { should contain_package('make') }
    it { should_not contain_package('perl-core') }
    it { should contain_file('/var/cache/cpanm-install')
      .with_source('puppet:///modules/cpanm/cpanm')
    }
    it { should contain_exec('/usr/bin/perl /var/cache/cpanm-install  -n App::cpanminus') }
  end
  context 'on Debian with mirror' do
    let(:params) {
        { :mirror => 'http://mirror.test.anywhere/cpan/' }
    }
    let(:facts) { {
      :osfamily => "Debian",
      :operatingsystemmajrelease => "8"
    } }
    it { should contain_class('cpanm') }
    it { should contain_package('perl') }
    it { should contain_package('gcc') }
    it { should contain_package('make') }
    it { should_not contain_package('perl-core') }
    it { should contain_file('/var/cache/cpanm-install')
      .with_source('puppet:///modules/cpanm/cpanm')
    }
    it { should contain_exec('/usr/bin/perl /var/cache/cpanm-install --from http://mirror.test.anywhere/cpan/ -n App::cpanminus') }
  end
  context 'on RHEL7 with default parameters' do
    let(:facts) { {
      :osfamily => "RedHat",
      :operatingsystemmajrelease => "7"
    } }
    it { should contain_class('cpanm') }
    it { should contain_package('perl') }
    it { should contain_package('gcc') }
    it { should contain_package('make') }
    it { should contain_package('perl-core') }
    it { should contain_file('/var/cache/cpanm-install')
      .with_source('puppet:///modules/cpanm/cpanm')
    }
    it { should contain_exec('/usr/bin/perl /var/cache/cpanm-install  -n App::cpanminus') }
  end
end
