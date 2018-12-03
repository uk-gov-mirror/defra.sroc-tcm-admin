module RegimeSetup
  def setup_cfd
    @regime = regimes(:cfd)
    @user = users(:billing_admin)
    sign_in @user
  end

  def setup_pas
    @regime = regimes(:pas)
    @user = users(:pas_billing_admin)
    sign_in @user
  end

  def setup_wml
    @regime = regimes(:wml)
    @user = users(:wml_billing_admin)
    sign_in @user
  end
end
