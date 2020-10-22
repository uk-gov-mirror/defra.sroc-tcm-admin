# frozen_string_literal: true

module GenerateHistory
  def generate_historic_cfd
    f = transaction_files(:cfd_sroc_file)
    t = transaction_details(:cfd)
    history = []
    t2 = t.dup
    t2.reference_1 = "AAAA/1/1"
    t2.reference_2 = "1"
    t2.reference_3 = "1"
    t2.customer_reference = "A1234"
    t2.status = "billed"
    t2.line_amount = 12_567
    t2.category = "2.3.4"
    t2.period_start = "1-APR-2018"
    t2.period_end = "31-MAR-2019"
    t2.tcm_financial_year = "1819"
    t2.transaction_file_id = f.id
    t2.save!
    history << t2
    t3 = t2.dup
    t3.reference_1 = "AAAA/1/2"
    t3.reference_3 = "2"
    t3.line_amount = 32_411
    t3.category = "2.3.5"
    t3.period_start = "1-APR-2018"
    t3.period_end = "31-MAR-2019"
    t3.tcm_financial_year = "1819"
    t3.transaction_file_id = f.id
    t3.save!
    history << t3
    t4 = t2.dup
    t4.reference_1 = "AAAB/1/1"
    t4.reference_3 = "1"
    t4.line_amount = 32_560
    t4.category = "2.3.4"
    t4.period_start = "1-APR-2018"
    t4.period_end = "31-MAR-2019"
    t4.tcm_financial_year = "1819"
    t4.transaction_file_id = f.id
    t4.save!
    history << t4
    t5 = t2.dup
    t5.reference_1 = "AAAC/1/1"
    t5.reference_3 = "1"
    t5.customer_reference = "C1234"
    t5.line_amount = 32_560
    t5.category = "2.3.4"
    t5.period_start = "1-APR-2018"
    t5.period_end = "31-MAR-2019"
    t5.tcm_financial_year = "1819"
    t5.transaction_file_id = f.id
    t5.save!
    history << t5
    history
  end

  def generate_historic_with_supplemental_cfd
    history = generate_historic_cfd
    t = history[0].dup
    t.line_amount = -1234
    t.save!
    history << t
    t2 = t.dup
    t2.line_amount = 23_423
    t2.period_start = "1-APR-2018"
    t2.period_end = "30-JUN-2018"
    t2.save!
    history << t2
    t3 = t2.dup
    t3.line_amount = 1_212_414
    t3.reference_1 = "AAAA/2/1"
    t3.reference_2 = "2"
    t3.category = "2.3.6"
    t3.period_start = "1-JUL-2018"
    t3.period_end = "31-MAR-2019"
    t3.save!
    history << t3
    history
  end

  def generate_historic_wml
    f = transaction_files(:wml_sroc_file)
    t = transaction_details(:wml)
    history = []
    t2 = t.dup
    t2.reference_1 = "0123456"
    t2.reference_2 = "AAA/A0011"
    t2.reference_3 = "1"
    t2.transaction_reference = "E12344"
    t2.customer_reference = "A1234"
    t2.status = "billed"
    t2.line_amount = 12_567
    t2.category = "2.15.2"
    t2.period_start = "1-APR-2018"
    t2.period_end = "31-MAR-2019"
    t2.tcm_financial_year = "1819"
    t2.transaction_file_id = f.id
    t2.save!
    history << t2
    t3 = t2.dup
    t3.transaction_reference = "E12956"
    t3.line_amount = 32_411
    t3.category = "2.15.3"
    t3.period_start = "1-APR-2019"
    t3.period_end = "31-MAR-2020"
    t3.tcm_financial_year = "1920"
    t3.transaction_file_id = f.id
    t3.save!
    history << t3
    history
  end

  def generate_historic_pas
    f = transaction_files(:pas_sroc_file)
    t = transaction_details(:pas)
    history = []
    t2 = t.dup
    t2.reference_1 = "0123456"
    t2.reference_2 = "AAA/A0011"
    t2.reference_3 = "AAAA0001"
    t2.transaction_reference = "E12344"
    t2.customer_reference = "A1234"
    t2.status = "billed"
    t2.line_amount = 12_567
    t2.category = "2.4.5"
    t2.period_start = "1-APR-2018"
    t2.period_end = "31-MAR-2019"
    t2.tcm_financial_year = "1819"
    t2.transaction_file_id = f.id
    t2.save!
    history << t2
    t3 = t2.dup
    t3.transaction_reference = "E12956"
    t3.line_amount = 32_411
    t3.category = "2.4.6"
    t3.period_start = "1-APR-2019"
    t3.period_end = "31-MAR-2020"
    t3.tcm_financial_year = "1920"
    t3.transaction_file_id = f.id
    t3.save!
    history << t3
    t4 = t2.dup
    t4.reference_3 = "AAAA0009"
    t4.customer_reference = "A1234"
    t4.transaction_reference = "E93356"
    t4.line_amount = 8443
    t4.category = "2.4.5"
    t4.period_start = "1-APR-2019"
    t4.period_end = "31-MAR-2020"
    t4.tcm_financial_year = "1920"
    t4.transaction_file_id = f.id
    t4.save!
    history << t4
    history
  end
end
