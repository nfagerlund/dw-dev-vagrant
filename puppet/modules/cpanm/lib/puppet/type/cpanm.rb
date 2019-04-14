Puppet::Type.newtype(:cpanm) do
  @doc = "Manage CPAN modules with cpanminus"
  ensurable do
    attr_accessor :latest

    defaultto :installed
    newvalue(:absent) do
      if provider.exists?
        provider.destroy
      end
    end

    newvalue(:present) do
      unless provider.exists?
        provider.create
      end
    end
    aliasvalue(:installed, :present)

    newvalue(:latest) do
      unless provider.latest?
        provider.create
        return
      end
    end

    def insync?(is)
      @should.each do |should|
      case should
      when :present
        return true if is == :present
      when :latest
        return false if is == :absent
        return true if provider.latest?
      when :absent
        return true if is == :absent
      end
      end
      false
    end

  end

  # Make sure cpanm installation happens first
  autorequire(:class) do
    'cpanm'
  end

  newparam(:name, :namevar => true) do
    desc "The CPAN module to manage"
  end

  newparam(:force, :boolean => true) do
    desc "Force installation"
    defaultto :false
  end

  newparam(:test, :boolean => true) do
    desc "Run CPAN module tests"
    defaultto :false
  end

  newparam(:mirror) do
    desc "URL of the CPAN mirror to use"
  end
end
