module RegimeSetup
  def setup_cfd
    @regime = regimes(:cfd)
    @user = users(:billing_admin)
    install_user @user
  end

  def setup_pas
    @regime = regimes(:pas)
    @user = users(:pas_billing_admin)
    install_user @user
  end

  def setup_wml
    @regime = regimes(:wml)
    @user = users(:wml_billing_admin)
    install_user @user
  end

  def setup_cfd_read_only
    @regime = regimes(:cfd)
    @user = users(:cfd_read_only)
    install_user @user
  end

  def setup_pas_read_only
    @regime = regimes(:pas)
    @user = users(:pas_read_only)
    install_user @user
  end

  def setup_pas_read_only_export
    @regime = regimes(:pas)
    @user = users(:pas_read_only_export)
    install_user @user
  end

  def setup_wml_read_only
    @regime = regimes(:wml)
    @user = users(:wml_read_only)
    install_user @user
  end

  def install_user(user)
    Thread.current[:current_user] = user
    sign_in user
  end
end
