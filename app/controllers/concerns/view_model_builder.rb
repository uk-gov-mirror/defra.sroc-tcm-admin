module ViewModelBuilder
  extend ActiveSupport::Concern

  def build_transaction_files_view_model
    vm = ViewModels::TransactionFiles.new(regime: @regime,
                                          user: current_user)
    vm.region = params.fetch(:region, '')
    vm.prepost = params.fetch(:prepost, '')
    vm.search = params.fetch(:search, '')
    vm.page = params.fetch(:page, 1)
    vm.per_page = params.fetch(:per_page, 10)
    vm.sort = params.fetch(:sort, :last_name)
    vm.sort_direction = params.fetch(:sort_direction, 'asc')
    vm.check_params
    vm
  end

  def build_users_view_model
    vm = ViewModels::Users.new
    vm.regime = params.fetch(:regime, '')
    vm.role = params.fetch(:role, '')
    vm.search = params.fetch(:search, '')
    vm.page = params.fetch(:page, 1)
    vm.per_page = params.fetch(:per_page, 10)
    vm.sort = params.fetch(:sort, :last_name)
    vm.sort_direction = params.fetch(:sort_direction, 'asc')
    vm.check_params
    vm
  end

  def build_annual_billing_view_model
    vm = ViewModels::AnnualBillingData.new(regime: @regime,
                                           upload: @upload,
                                           user: current_user)
    vm.page = params.fetch(:page, 1)
    vm.per_page = params.fetch(:per_page, 10)
    vm.sort = params.fetch(:sort, :line_number)
    vm.sort_direction = params.fetch(:sort_direction, 'asc')
    vm
  end

  def build_exclusions_view_model
    vm = ViewModels::Exclusions.new(regime: @regime,
                                    user: current_user)
    populate_view_model(vm)
  end

  def build_history_view_model
    vm = ViewModels::Historic.new(regime: @regime,
                                  user: current_user)
    populate_view_model(vm)
  end

  def build_retrospectives_view_model
    vm = ViewModels::Retrospectives.new(regime: @regime,
                                        user: current_user)

    populate_view_model(vm)
  end

  def build_transactions_view_model
    vm = ViewModels::Transactions.new(regime: @regime,
                                      user: current_user)

    populate_view_model(vm)
  end

  def populate_view_model(vm)
    vm.region = param_or_cookie(:region, '')
    vm.page = param_or_cookie(:page, 1)
    vm.per_page = param_or_cookie(:per_page, 10)
    vm.financial_year = param_or_cookie(:fy, '')
    vm.search = param_or_cookie(:search, '')
    vm.sort = param_or_cookie(:sort, 'customer_reference')
    vm.sort_direction = param_or_cookie(:sort_direction, 'asc')
    vm.check_params
    vm
  end

  def param_or_cookie(attr, default_value)
    params.fetch(attr, cookies.fetch(attr, default_value))
  end
end
