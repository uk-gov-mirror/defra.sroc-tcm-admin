import React from 'react'
import axios from 'axios'
import TransactionSummary from './TransactionSummary'
import TransactionTable from './TransactionTable'
import SearchBar from './SearchBar'
import PaginationBar from './PaginationBar'
import { RegionFilter } from './RegionFilter'
import { TransactionSearchBox } from './TransactionSearchBox'

export default class TransactionsView extends React.Component {
  constructor (props) {
    super(props)
    const transactions = this.props.transactions || this.emptyTransactions()
    let region = this.props.selectedRegion
    if (region === null || typeof region == 'undefined' || region === '') {
      if(this.props.regions && this.props.regions.length > 0) {
        region = this.props.regions[0].value
      }
    }

    this.state = {
      sortColumn: this.props.sortColumn,
      sortDirection: this.props.sortDirection,
      transactions: transactions,
      selectedRegion: region,
      searchTerm: this.props.searchTerm,
      pageSize: transactions.pagination.per_page,
      currentPage: transactions.pagination.current_page,
      summary: this.emptySummary(),
      fileSummaryOpen: false
    }

    this.toggleSortDirection = this.toggleSortDirection.bind(this)
    this.changeSortColumn = this.changeSortColumn.bind(this)
    this.changeRegion = this.changeRegion.bind(this)
    this.search = this.search.bind(this)
    this.changePage = this.changePage.bind(this)
    this.changePageSize = this.changePageSize.bind(this)
    this.updateTransactionCategory = this.updateTransactionCategory.bind(this)
    this.showFileSummary = this.showFileSummary.bind(this)
    this.hideFileSummary = this.hideFileSummary.bind(this)
  }

  emptyTransactions () {
    const perPage = 10
    return {
      pagination: {
        per_page: perPage,
        current_page: 1
      },
      // NOTE: we need a polyfill for Array.prototype.fill on IE
      transactions: new Array(perPage).fill().map((_, i) => { return { id: i } })
    }
  }

  emptySummary () {
    return {
      credit_count: 0,
      credit_total: 0,
      invoice_count: 0,
      invoice_total: 0,
      net_total: 0
    }
  }

  toggleSortDirection () {
    const direction = this.state.sortDirection === 'asc' ? 'desc' : 'asc'
    this.setState({sortDirection: direction, currentPage: 1}, () => {
      this.fetchTableData()
    })
  }

  changeSortColumn (columnName) {
    this.setState({sortColumn: columnName, sortDirection: 'asc', currentPage: 1}, () => {
      this.fetchTableData()
    })
  }

  changeRegion (region) {
    this.setState({selectedRegion: region, currentPage: 1}, () => {
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
    this.setState({pageSize: size}, () => {
      this.fetchTableData()
    })
  }

  showFileSummary () {
    console.log('show file summary')
    this.fetchSummaryDataAndShow()
    // query for all transactions to be billed that have a charge generated for them
    // but exclude any that have are part of multi-transactions if one or more other
    // items haven't had charges generated
  }

  hideFileSummary () {
    console.log('hide file summary')
    this.setState({fileSummaryOpen: false})
  }

  generateFile () {
    console.log('generate file')
  }

  componentDidMount () {
    this.fetchTableData()
  }

  fetchTableData () {
    axios.get(this.props.path + '.json', {
      params: {
        sort: this.state.sortColumn,
        sort_direction: this.state.sortDirection,
        region: this.state.selectedRegion,
        search: this.state.searchTerm,
        page: this.state.currentPage,
        per_page: this.state.pageSize
      }
    })
      .then(res => {
        this.setState({
          transactions: res.data,
          pagination: res.data.pagination,
          pageSize: res.data.pagination.per_page,
          currentPage: res.data.pagination.current_page
        })
      })
      .catch(error => {
        // TODO: handle this
        console.log(error)
        throw error
      })
  }

  fetchSummaryDataAndShow () {
    axios.get(this.props.summaryPath + '.json', {
      params: {
        region: this.state.selectedRegion,
      }
    })
      .then(res => {
        console.log(res)
        this.setState({
          summary: res.data,
          fileSummaryOpen: true
        })
      })
      .catch(error => {
        // TODO: handle this
        console.log(error)
        throw error
      })
  }

  updateTransactionCategory (id, value) {
    axios.patch(this.props.path + '/' + id + '.json',
      {
        transaction_detail: {
          category: value
        }
      },
      {
        headers: {
          'X-CSRF-Token': this.props.csrfToken
        }
      })
    .then(res => {
      // update local data
      let data = this.state.transactions
      let idx = data.transactions.findIndex(t => {
        return t.id === id
      })
      if (idx !== -1) {
        data.transactions[idx] = res.data.transaction
        console.log(res.data.transaction)
        this.setState({ transactions: data })
      }
    })
    .catch(error => {
      // problem accessing or executing the rules service
      console.log('error: ' + error)
    })
  }

  render () {
    const regime = this.props.regime
    const columns = this.props.columns
    const sortColumn = this.state.sortColumn
    const sortDirection = this.state.sortDirection
    const transactions = this.state.transactions.transactions
    const pagination = this.state.transactions.pagination
    const regions = this.props.regions
    const selectedRegion = this.state.selectedRegion
    const searchTerm = this.state.seachTerm
    const searchPlaceholder = this.props.searchPlaceholder
    const currentPage = this.state.currentPage
    const pageSize = this.state.pageSize
    const summary = this.state.summary
    const categories = this.props.categories
    const canGenerateFiles = this.props.generateFiles
    const generateFilePath = this.props.generateFilePath
    const csrfToken = this.props.csrfToken

    let fileButton = null
    let fileDialog = null
    if (canGenerateFiles) {
      fileButton = (
        <button className='btn btn-primary' onClick={this.showFileSummary}>
          Generate Transaction File
        </button>
      )
      fileDialog = (
        <TransactionSummary id='summary-dialog2112'
          show={this.state.fileSummaryOpen}
          summary={summary}
          generateFilePath={generateFilePath}
          region={selectedRegion}
          csrfToken={csrfToken}
          onClose={this.hideFileSummary} />
      )
    }

    return (
      <div>
        <SearchBar>
          <RegionFilter regions={regions}
            selectedRegion={selectedRegion}
            onChangeRegion={this.changeRegion}
          />
          <TransactionSearchBox placeholder={searchPlaceholder}
            searchTerm={searchTerm} onSearch={this.search}
          />
          {fileButton}
        </SearchBar>
        <TransactionTable regime={regime}
          columns={columns}
          sortColumn={sortColumn}
          sortDirection={sortDirection}
          data={transactions}
          categories={categories}
          onChangeSortDirection={this.toggleSortDirection}
          onChangeSortColumn={this.changeSortColumn}
          onChangeCategory={this.updateTransactionCategory}
        />
        <PaginationBar pagination={pagination}
          pageSize={pageSize}
          currentPage={currentPage}
          onChangePageSize={this.changePageSize}
          onChangePage={this.changePage}
        />
        {fileDialog}
      </div>
    )
  }
}
