module GenerateHistory
  def generate_historic_cfd
    f = transaction_files(:cfd_sroc_file)
    t = transaction_details(:cfd)
    history = []
    t2 = t.dup
    t2.reference_1 = 'AAAA/1/1'
    t2.reference_2 = '1' 
    t2.reference_3 = '1'
    t2.customer_reference = 'A1234'
    t2.status = 'billed'
    t2.line_amount = 12567
    t2.category = '2.3.4'
    t2.period_start = '1-APR-2018'
    t2.period_end = '31-MAR-2019'
    t2.tcm_financial_year = '1819'
    t2.transaction_file_id = f.id
    t2.save!
    history << t2
    t3 = t2.dup
    t3.line_amount = 32411
    t3.category = '2.3.5'
    t3.period_start = '1-APR-2019'
    t3.period_end = '31-MAR-2020'
    t3.tcm_financial_year = '1920'
    t3.transaction_file_id = f.id
    t3.save!
    history << t3
    history
  end

  def generate_historic_wml
    f = transaction_files(:wml_sroc_file)
    t = transaction_details(:wml)
    history = []
    t2 = t.dup
    t2.reference_1 = '0123456'
    t2.reference_2 = 'AAA/A0011' 
    t2.reference_3 = '1'
    t2.transaction_reference = 'E12344'
    t2.customer_reference = 'A1234'
    t2.status = 'billed'
    t2.line_amount = 12567
    t2.category = '2.15.2'
    t2.period_start = '1-APR-2018'
    t2.period_end = '31-MAR-2019'
    t2.tcm_financial_year = '1819'
    t2.transaction_file_id = f.id
    t2.save!
    history << t2
    t3 = t2.dup
    t3.transaction_reference = 'E12956'
    t3.line_amount = 32411
    t3.category = '2.15.3'
    t3.period_start = '1-APR-2019'
    t3.period_end = '31-MAR-2020'
    t3.tcm_financial_year = '1920'
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
    t2.reference_1 = '0123456'
    t2.reference_2 = 'AAA/A0011' 
    t2.reference_3 = 'AAAA0001'
    t2.transaction_reference = 'E12344'
    t2.customer_reference = 'A1234'
    t2.status = 'billed'
    t2.line_amount = 12567
    t2.category = '2.4.4'
    t2.period_start = '1-APR-2018'
    t2.period_end = '31-MAR-2019'
    t2.tcm_financial_year = '1819'
    t2.transaction_file_id = f.id
    t2.save!
    history << t2
    t3 = t2.dup
    t3.transaction_reference = 'E12956'
    t3.line_amount = 32411
    t3.category = '2.4.5'
    t3.period_start = '1-APR-2019'
    t3.period_end = '31-MAR-2020'
    t3.tcm_financial_year = '1920'
    t3.transaction_file_id = f.id
    t3.save!
    history << t3
    history
  end
end
