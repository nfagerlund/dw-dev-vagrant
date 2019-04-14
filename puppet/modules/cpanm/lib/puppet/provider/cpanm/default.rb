Puppet::Type.type(:cpanm).provide(:default) do
  desc 'Manage CPAN modules with cpanm'

  commands :cpanm => 'cpanm'
  commands :perl => 'perl'
  commands :perldoc => 'perldoc'

  def latest?
    begin
      installed=perl "-m#{@resource[:name]}", "-eprint $#{@resource[:name]}::VERSION",  '2>/dev/null'
    rescue Puppet::ExecutionFailure
      installed=''
    end
    options = []
    if @resource[:mirror]
      options << "--from"
      options << @resource[:mirror]
    end
    options << '--info'
    options << @resource[:name]

    cpan=cpanm(options).split("\n")[-1].match(/([0-9]+\.?[0-9]*).tar.gz/)
    if cpan
      latest = cpan[1]
      Puppet.debug("Installed: #{installed}, CPAN: #{latest}")
      if latest > installed
        return false
      end
    end
    return true
  end

  def create
    options = []

    if @resource[:mirror]
      options << "--from"
      options << @resource[:mirror]
    end

    if @resource[:force] == :true
      options << "-f"
    end

    if @resource[:test] == :false
      options << "-n"
    end

    options << @resource[:name]

    cpanm(options)
  end

  #  alias update create
  def destroy
    begin
      cpanm '-U', '-f', @resource[:name]
    rescue Puppet::ExecutionFailure
      #error = Puppet::Error.new("Failed to remove CPAN package: #{e}")
      #error.set_backtrace(e.backtrace)
      #raise error
    end
  end

  def exists?
    begin
      perl "-M#{@resource[:name]}", '-e1', '>/dev/null', '2>&1'
    rescue Puppet::ExecutionFailure
      false
    end
  end

  def self.instances
    modules = {}
    name = nil
    perldoc('-tT', 'perllocal').split("\n").each do |r|
      if r.include?('"Module"') then
        name = r.split[-1]
        modules[name] = new(:name => name)
      end
      if r.include?('VERSION: ') and name
        r.split[-1].delete('"')
        #modules[name].version = version
      end
    end
    modules.map do |k,v| v end
  end
end
