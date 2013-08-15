require "fileutils"
require "securerandom"

module BoshWorkstationCpi::Actions
  class CreateStemcell
    # @param [String] image_path path to an opaque blob containing the stemcell image
    # @param [Hash] cloud_properties properties required for creating this template specific to a CPI
    def initialize(stemcell_manager, image_path, cloud_properties, logger)
      @stemcell_manager = stemcell_manager
      @image_path = image_path
      @cloud_properties = cloud_properties
      @logger = logger
    end

    def run
      dir         = extract_stemcell
      ovf_path    = check_ovf_file(dir)
      stemcell_id = store_stemcell(dir)
    ensure
      clean_up_extracted_stemcell(dir)
    end

    private

    def extract_stemcell
      Dir.mktmpdir.tap do |dir|
        @logger.info("Extracting stemcell to #{dir}")
        output = `tar -C #{dir} -xzf #{@image_path} 2>&1`
        raise "Corrupt image, tar exit status: #{$?.exitstatus} output: #{output}" \
          unless $?.exitstatus.zero?
      end
    end

    def check_ovf_file(dir)
      @logger.info("Checking OVF file in #{dir}")
      ovf_file = Dir.entries(dir).find { |entry| File.extname(entry) == ".ovf" }
      raise "Missing OVF file" if ovf_file.nil?
      File.join(dir, ovf_file)
    end

    def store_stemcell(dir)
      @logger.info("Storing stemcell")
      @stemcell_manager.create(dir)
    end

    def clean_up_extracted_stemcell(dir)
      FileUtils.rm_rf(dir) if dir
    end
  end
end
