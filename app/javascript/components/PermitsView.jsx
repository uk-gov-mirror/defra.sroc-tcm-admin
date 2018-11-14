import React from 'react'
import axios from 'axios'
import TransactionTable from './TransactionTable'
import PaginationBar from './PaginationBar'
import OptionSelector from './OptionSelector'
import Constants from './constants'
import TransactionSearchBox from './TransactionSearchBox'

export default class PermitsView extends React.Component {
  constructor (props) {
    super(props)
    const categories = this.props.categories || this.emptyCategories()
    const selectedFinancialYear = this.props.financialYear || '1819'

    this.state = {
      sortColumn: this.props.sortColumn,
      sortDirection: this.props.sortDirection,
      categories: categories,
      selectedFinancialYear: selectedFinancialYear,
      searchTerm: this.props.searchTerm,
      pageSize: categories.pagination.per_page,
      currentPage: categories.pagination.current_page
    }

    this.changeFinancialYear = this.changeFinancialYear.bind(this)
    this.toggleSortDirection = this.toggleSortDirection.bind(this)
    this.changeSortColumn = this.changeSortColumn.bind(this)
    this.search = this.search.bind(this)
    this.changePage = this.changePage.bind(this)
    this.changePageSize = this.changePageSize.bind(this)
    this.newPermitCategory = this.newPermitCategory.bind(this)
    this.editPermitCategory = this.editPermitCategory.bind(this)
  }

  emptyCategories () {
    const perPage = 10
    return {
      pagination: {
        per_page: perPage,
        current_page: 1
      },
      permit_categories: [{id: 1}]
    }
  }

  changeFinancialYear (fy) {
    this.setState({selectedFinancialYear: fy}, () => {
      this.fetchTableData()
    })
  }

  toggleSortDirection () {
    const direction = this.state.sortDirection === 'asc' ? 'desc' : 'asc'
    this.setState({sortDirection: direction, currentPage: 1}, () => {
      this.fetchTableData()
    })
  }

  changeSortColumn (columnName) {
    this.setState({
      sortColumn: columnName,
      sortDirection: 'asc',
      currentPage: 1
    }, () => {
      this.fetchTableData()
    })
  }

  search (term) {
    this.setState({searchTerm: term, currentPage: 1}, () => {
      this.fetchTableData()
    })
  }

  changePage (page) {
    this.setState({currentPage: page}, () => {
      this.fetchTableData()
    })
  }

  changePageSize (size) {
    // need to ensure we don't fall off the end into no-man's land by being on
    // the last page and making the page size larger
    const pagination = this.state.categories.pagination
    const total = pagination.total_count
    const pageSize = this.state.pageSize
    let currentPage = this.state.currentPage
    const numPages = (total / size) + 1

    if (numPages < currentPage) {
      currentPage = Math.max(1, numPages)
    }

    this.setState({pageSize: size, currentPage: currentPage}, () => {
      this.fetchTableData()
    })
  }

  componentDidMount () {
    this.fetchTableData()
  }

  fetchTableData () {
    axios.get(this.categoriesPath() + '.json', {
      params: {
        sort: this.state.sortColumn,
        sort_direction: this.state.sortDirection,
        fy: this.state.selectedFinancialYear,
        search: this.state.searchTerm,
        page: this.state.currentPage,
        per_page: this.state.pageSize,
        mode: 'edit'
      }
    })
      .then(res => {
        console.log(res)
        this.setState({
          categories: res.data,
          pagination: res.data.pagination,
          pageSize: res.data.pagination.per_page,
          currentPage: res.data.pagination.current_page
        })
      })
      .catch(error => {
        this.handleXhrError(error)
      })
  }

  handleXhrError(error) {
    // more than likely we've got a 401 because our session has timed-out
    if (error.response.status === 401) {
      // force reauthentication
      window.location.reload(true)
    } else {
      console.log(error)
      throw error
    }
  }

  categoriesPath () {
    const regime = this.props.regime
    return '/regimes/' + regime + '/permit_categories'
  }

  newPermitCategory () {
    const fy = this.state.selectedFinancialYear
    const uri = this.categoriesPath() + '/new?fy=' + fy
    console.log('New category: ' + uri)
    if (typeof Turbolinks !== 'undefined') {
      console.log('new via turbolinks')
      Turbolinks.visit(uri)
    } else {
      window.location.replace(uri)
    }
  }

  editPermitCategory (id) {
    const fy = this.state.selectedFinancialYear
    const uri = this.categoriesPath() + '/' + id + '/edit?fy=' + fy
    console.log('Edit row: ' + uri)
    if (typeof Turbolinks !== 'undefined') {
      console.log('edit via turbolinks')
      Turbolinks.visit(uri)
    } else {
      window.location.replace(uri)
    }
  }

  render () {
    const regime = this.props.regime
    const columns = Constants.PERMIT_CATEGORY_COLUMNS
    const sortColumn = this.state.sortColumn
    const sortDirection = this.state.sortDirection
    const categories = this.state.categories.permit_categories
    const pagination = this.state.categories.pagination
    const searchTerm = this.state.seachTerm
    const searchPlaceholder = this.props.searchPlaceholder
    const currentPage = this.state.currentPage
    const pageSize = this.state.pageSize
    const csrfToken = this.props.csrfToken
    const selectedFinancialYear = this.state.selectedFinancialYear

    return (
      <div>
        <div className='row search-bar'>
          <div className='col mb-2 form-inline'>
            <div className='mr-4'>
              <OptionSelector selectedValue={selectedFinancialYear}
                label='Financial Year'
                className='form-control'
                options={Constants.FINANCIAL_YEARS}
                name='financial-year'
                id='financial-year'
                onChange={this.changeFinancialYear}
              />
            </div>
            <TransactionSearchBox placeholder={searchPlaceholder}
              searchTerm={searchTerm} onSearch={this.search}
            />
            <button className='btn btn-primary'
              onClick={this.newPermitCategory}>
              New Permit Category
            </button>
          </div>
        </div>
        <TransactionTable regime={regime}
          columns={columns}
          sortColumn={sortColumn}
          sortDirection={sortDirection}
          data={categories}
          onChangeSortDirection={this.toggleSortDirection}
          onChangeSortColumn={this.changeSortColumn}
          onEditRow={this.editPermitCategory}
        />
        <PaginationBar pagination={pagination}
          useMatchingLabel={true}
          pageSize={pageSize}
          currentPage={currentPage}
          onChangePageSize={this.changePageSize}
          onChangePage={this.changePage}
        />
      </div>
    )
  }
}
