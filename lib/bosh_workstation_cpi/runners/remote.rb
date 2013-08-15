require "net/ssh"
require "net/scp"
require "tempfile"
require "shellwords"
require "bosh_workstation_cpi/runners/base"

module BoshWorkstationCpi::Runners
  class Remote < Base
    def initialize(host, user, password, *args)
      super(*args)
      @host = host
      @user = user
      @password = password
      @ssh_lock = Mutex.new
    end

    def execute_raw(cmd)
      logger.info("remote_runner.#{__method__} host=#{cmd}")

      exit_status = nil
      output = ""

      record_exit_status = \
        proc { |_, data| exit_status = data.read_long }

      ssh_lock do
        ssh.open_channel do |ch|
          ch.exec(cmd) do |_, success|
            raise Error, "Command '#{cmd}' failed to start" unless success
            ch.on_data          { |   _, data| output += data.to_s }
            ch.on_extended_data { |_, _, data| output += data.to_s }
            ch.on_request("exit-status", &record_exit_status)
            ch.on_request("exit-signal", &record_exit_status)
          end
        end
        ssh.loop
      end

      [exit_status, output]
    end

    def upload!(src_dir, dst_dir)
      ssh_lock { ssh.scp.upload!(src_dir, dst_dir, recursive: true) }
    end

    def put!(dst_path, contents)
      tmp = Tempfile.new("remote_runner.put")
      tmp.write(contents)
      tmp.flush
      ssh_lock { ssh.scp.upload!(tmp.path, dst_path) }
    end

    def get!(dst_path)
      tmp = Tempfile.new("remote_runner.get")
      ssh_lock { ssh.scp.download!(dst_path, tmp.path) }
      File.read(tmp.path)
    end

    private

    def ssh
      # Configuration options that avoid searching
      # are needed to stop resolving '~' deep inside Net::SSH. 
      # Resolution of '~' does not work since HOME env is not set.
      @ssh ||= Net::SSH.start(@host, @user, {
        password: @password, 
        paranoid: false, 
        config: false, # avoids ~
        host_key: [],  # avoids ~
        keys: [],      # avoids ~
      })
    end

    def ssh_lock(&blk)
      @ssh_lock.synchronize(&blk)
    end
  end
end
