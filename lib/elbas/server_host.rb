module Elbas
  module ServerHost
    HOST_SOURCES = %i[public_dns public_ip instance_id].freeze

    def elbas_server_host(instance)
      source = fetch(:elbas_server_host, :public_dns).to_sym
      unless HOST_SOURCES.include?(source)
        raise ArgumentError, "elbas_server_host must be one of #{HOST_SOURCES.join(', ')}"
      end

      host = case source
             when :instance_id then instance.id
             when :public_ip then instance.public_ip
             else instance.hostname
             end

      if host.to_s.empty?
        raise ArgumentError, "Instance #{instance.id} has no #{source} to use as SSH host"
      end

      host
    end

    def elbas_ssh_command(server)
      target = "#{fetch(:user)}@#{server.hostname}"
      return "ssh #{target}" unless fetch(:elbas_server_host, :public_dns).to_sym == :instance_id

      proxy = "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
      %(ssh -o ProxyCommand="#{proxy}" #{target})
    end
  end
end
