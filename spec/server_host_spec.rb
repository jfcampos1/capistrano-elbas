require 'elbas/capistrano'

describe 'SSH host selection' do
  let(:instance) { Elbas::AWS::Instance.new('i-123', 'ec2.example.com', 16, '1.2.3.4') }

  before do
    Capistrano::Configuration.reset!
    Rake::Task.define_task('deploy') {} unless Rake::Task.task_defined?('deploy')

    asg = instance_double('Elbas::AWS::AutoscaleGroup')
    allow(asg).to receive(:instances).and_return(double(running: [instance]))
    allow(Elbas::AWS::AutoscaleGroup).to receive(:new).and_return(asg)
  end

  it 'registers the public DNS by default' do
    autoscale 'test-asg'
    expect(env.servers.first.hostname).to eq 'ec2.example.com'
  end

  it 'registers the public IP when configured' do
    set :elbas_server_host, :public_ip
    autoscale 'test-asg'
    expect(env.servers.first.hostname).to eq '1.2.3.4'
  end

  it 'registers the instance id when configured' do
    set :elbas_server_host, :instance_id
    autoscale 'test-asg'
    expect(env.servers.first.hostname).to eq 'i-123'
  end

  it 'rejects an unknown source' do
    set :elbas_server_host, :private_ip
    expect { elbas_server_host(instance) }.to raise_error(ArgumentError, /elbas_server_host/)
  end

  it 'rejects a blank public IP' do
    bare = Elbas::AWS::Instance.new('i-abc', 'ec2.example.com', 16, nil)
    set :elbas_server_host, :public_ip
    expect { elbas_server_host(bare) }.to raise_error(ArgumentError, /no public_ip/)
  end

  it 'prints an SSM proxy command for instance ids' do
    set :elbas_server_host, :instance_id
    set :user, 'ubuntu'
    autoscale 'test-asg'
    expect(elbas_ssh_command(env.servers.first)).to include('i-123').and include('AWS-StartSSHSession')
  end

  it 'prints a direct ssh command for the public DNS' do
    set :user, 'ubuntu'
    autoscale 'test-asg'
    expect(elbas_ssh_command(env.servers.first)).to eq 'ssh ubuntu@ec2.example.com'
  end
end
