module GenerateHistory
  def generate_historic_cfd
    f = transaction_files(:cfd_sroc_file)
    t = transaction_details(:cfd)
    history = []
    tt = t.dup
    tt.reference_1 = 'AAAA/1/1'
    tt.reference_2 = '1' 
    tt.reference_3 = '1'
    tt.customer_reference = 'A1234'
    tt.status = 'billed'
    tt.line_amount = 12567
    tt.category = '2.3.4'
    tt.period_start = '1-APR-18'
    tt.period_end = '31-MAR-19'
    tt.tcm_financial_year = '1819'
    tt.transaction_file_id = f.id
    tt.save!
    history << tt
    ttt = tt.dup
    ttt.line_amount = 32411
    ttt.category = '2.3.5'
    ttt.period_start = '1-APR-19'
    ttt.period_end = '31-MAR-20'
    ttt.tcm_financial_year = '1920'
    tt.transaction_file_id = f.id
    ttt.save!
    history << ttt
    history
  end
end
