module AnnualBillingDataFileFormat
  FileTypes = %w[ .csv ].freeze

  Descriptions = {
    consent_reference: "Unique consent reference including discharge and version",
    permit_reference: "Unique permit reference",
    region: "Single letter region identifier",
    permit_category: "Permit category code to assign to the transaction e.g. '2.3.1'",
    variation: "A percentage variation charge modifier e.g. 96",
    temporary_cessation: "Whether temporary cessation applies, either 'Y' or 'N'",
    temporary_cessation_start: "Date temporary cessation start in DD-MMM-YYYY format e.g. '12-MAY-2018'",
    temporary_cessation_end: "Date temporary cessation ends in DD-MMM-YYYY format e.g. '01-FEB-2019'",
  }.freeze

  module CFD
    Headers = [
      {
        header: :consent_reference,
        column: :reference_1,
        unique_reference: true,
        mandatory: true
      },
      # {
      #   header: :region,
      #   column: :region,
      #   mandatory: true
      # },
      {
        header: :permit_category,
        column: :category,
        mandatory: true
      },
      {
        header: :variation,
        column: :variation,
        mandatory: false
      },
      {
        header: :temporary_cessation,
        column: :temporary_cessation,
        mandatory: false
      },
      # {
      #   header: :temporary_cessation_start,
      #   column: :temporary_cessation_start,
      #   mandatory: false
      # },
      # {
      #   header: :temporary_cessation_end,
      #   column: :temporary_cessation_end,
      #   mandatory: false
      # }
    ].freeze
  end

  module PAS
    Headers = [
      {
        header: :permit_reference,
        column: :reference_1,
        unique_reference: true,
        mandatory: true
      },
      # {
      #   header: :region,
      #   column: :region,
      #   mandatory: true
      # },
      {
        header: :permit_category,
        column: :category,
        mandatory: true
      },
      {
        header: :temporary_cessation,
        column: :temporary_cessation,
        mandatory: false
      },
      # {
      #   header: :temporary_cessation_start,
      #   column: :temporary_cessation_start,
      #   mandatory: false
      # },
      # {
      #   header: :temporary_cessation_end,
      #   column: :temporary_cessation_end,
      #   mandatory: false
      # }
    ].freeze
  end

  module WML
    Headers = [
      {
        header: :permit_reference,
        column: :reference_1,
        unique_reference: true,
        mandatory: true
      },
      # {
      #   header: :region,
      #   column: :region,
      #   mandatory: true
      # },
      {
        header: :permit_category,
        column: :category,
        mandatory: true
      },
      {
        header: :temporary_cessation,
        column: :temporary_cessation,
        mandatory: false
      },
      # {
      #   header: :temporary_cessation_start,
      #   column: :temporary_cessation_start,
      #   mandatory: false
      # },
      # {
      #   header: :temporary_cessation_end,
      #   column: :temporary_cessation_end,
      #   mandatory: false
      # }
    ].freeze
  end

  def present_column(sym)
    sym.to_s.humanize.capitalize
  end

  %w[ CFD PAS WML ].each do |regime|
    prefix = regime.downcase

    define_method "#{prefix}_columns" do
      "AnnualBillingDataFileFormat::#{regime}::Headers".constantize
    end

    define_method "#{prefix}_column_names" do
      "AnnualBillingDataFileFormat::#{regime}::Headers".constantize.map { |h| h[:header] }
    end

    define_method "#{prefix}_mandatory_column_names" do
      "AnnualBillingDataFileFormat::#{regime}::Headers".constantize.select { |h| h[:mandatory] }.
        map { |h| h[:header] }
    end
  end
end
