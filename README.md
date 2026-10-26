*Versions < 3 of ELBAS are no longer being maintained. I will only be maintaining the current feature-set which relies on Launch Templates and AWS SDK v3.*

# Capistrano ELBAS (Elastic Load Balancer & AutoScaling)

[![Gem Version](https://badge.fury.io/rb/elbas.svg)](https://badge.fury.io/rb/elbas)

ELBAS was written to ease the deployment of Rails applications to AWS AutoScale
groups. During your Capistrano deployment, ELBAS will:

- Deploy your code to each running instance connected to a given AutoScale group
- After deployment, create an AMI from one of the running instances
- Update the AutoScale group's launch template with the AMI ID
- Delete any outdated AMIs created by previous ELBAS deployments

## Installation

Add to Gemfile, then `bundle`:

`gem 'elbas'`

Add to Capfile:

`require 'elbas/capistrano'`

## Configuration

Setup AWS credentials:

```ruby
set :aws_access_key, ENV['AWS_ACCESS_KEY_ID']
set :aws_secret_key, ENV['AWS_SECRET_ACCESS_KEY']
set :aws_region,     ENV['AWS_REGION']
```

## Usage

Instead of using Capistrano's `server` method, use `autoscale` instead in
`deploy/<environment>.rb` (replace <environment> with your environment). Provide
the name of your AutoScale group instead of a hostname:

```ruby
autoscale 'my-autoscale-group', user: 'apps', roles: [:app, :web, :db]
```

If you have multiple autoscaling groups to deploy to, specify each of them:

```ruby
autoscale 'app-autoscale-group', user: 'apps', roles: [:app, :web]
autoscale 'worker-autoscale-group', user: 'apps', roles: [:worker]
```

Run `cap production deploy`.

### SSH host

By default each server is registered with its public DNS name, and Capistrano
connects there over SSH. Set `elbas_server_host` to use another address. The
same value is used when choosing which instance to bake into the AMI.

```ruby
set :elbas_server_host, :public_dns   # default
set :elbas_server_host, :public_ip
set :elbas_server_host, :instance_id  # target for SSH over SSM Session Manager
```

`:instance_id` does not open the tunnel by itself. Pass an SSH `ProxyCommand`
in `ssh_options` so Net::SSH substitutes the instance id into `%h`:

```ruby
set :elbas_server_host, :instance_id

autoscale 'my-autoscale-group', user: 'apps', roles: [:app, :web, :db],
  ssh_options: {
    keys: ['~/.ssh/my-key.pem'],
    verify_host_key: :never,
    proxy: Net::SSH::Proxy::Command.new(
      "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p' --region us-east-1"
    )
  }
```

`cap <stage> elbas:ssh` prints a direct `ssh user@host` for `:public_dns` and
`:public_ip`, and the same command with that `ProxyCommand` for `:instance_id`.

**As of version 3, your AWS setup must use launch templates as opposed to launch
configurations.** This allows ELBAS to simply create a new launch template version
with the new AMI ID after a deployment. It no longer needs to update your
AutoScale group or mess around with network settings, instance sizes, etc., as
that information is all contained within the launch template. Failure to use a
launch template will result in a `Elbas::Errors::NoLaunchTemplate` error.

### Customizing Server Properties

You can pass a block to `autoscale` and return properties for any specific server.
The block accepts the server and the server's index as arguments.

For example, if you want to apply the `:db` role to only the first server:

```ruby
autoscale 'my-autoscale-group', roles: [:app, :web] do |server, i|
  { roles: [:app, :web, :db] } if i == 0
end
```

Returning `nil` from this block will cause the server to use the properties
passed to `autoscale`.

Returning anything but `nil` will override the entire properties hash (as
opposed to merging the two hashes together).

### Listing Servers

You may need to SSH into your servers while debugging deployed code, and
not everyone has a jumpbox on a basic AutoScaling setup. ELBAS provides a command
that will list the `ssh` command necessary to connect to each server in any given
environment:

```
cap production elbas:ssh
```

Output will be something like:

```
[ELBAS] Adding server: ec2-12-34-567-890.compute-1.amazonaws.com
[ELBAS] SSH commands:
[ELBAS]     1) ssh deploy@ec2-12-34-567-890.compute-1.amazonaws.com
```
