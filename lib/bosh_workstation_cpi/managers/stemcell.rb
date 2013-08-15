require "securerandom"

module BoshWorkstationCpi::Managers
  class Stemcell
    PREFIX = "sc"

    def initialize(stemcells_dir, runner, logger)
      @stemcells_dir = stemcells_dir
      @runner = runner
      @logger = logger
    end

    def path(id)
      "#{@stemcells_dir}/#{id}"
    end

    def create(dir)
      create_stemcells_dir
      id = "#{PREFIX}-#{SecureRandom.uuid}"
      @logger.debug("managers.stemcell.#{__method__} id=#{id} dir=#{dir}")
      @runner.upload!(dir, path(id))
      id
    end

    def exists?(id)
      @logger.debug("managers.stemcell.#{__method__} id=#{id}")
      exit_status, _ = @runner.execute("ls", path(id))
      exit_status.zero?
    end

    def delete(id)
      create_stemcells_dir
      @logger.debug("managers.stemcell.#{__method__} id=#{id}")
      @runner.execute!("rm", "-rf", path(id))
    end

    private

    def create_stemcells_dir
      @logger.debug("managers.stemcell.#{__method__} dir=#{@stemcells_dir}")
      @runner.execute!("mkdir", "-p", @stemcells_dir)
    end
  end
end
