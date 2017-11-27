import React from 'react'

export class TransactionSearchBox extends React.Component {
  constructor (props) {
    super(props)
    this.handleSearchBtn = this.handleSearchBtn.bind(this)
    this.handleKeyPress = this.handleKeyPress.bind(this)
  }

  handleSearchBtn (ev) {
    this.doSearch()
  }

  handleKeyPress (ev) {
    if (ev.key === 'Enter') {
      this.doSearch()
    }
  }

  doSearch () {
    this.props.onSearch(document.getElementById('transaction-search').value)
  }

  render () {
    const searchTerm = this.props.searchTerm
    const placeholder = this.props.placeholder

    return (
      <div className='input-group col-12 col-md-6 ml-4'>
        <label htmlFor='transaction-search' className='sr-only'>Search</label>
        <input type='search' name='search' id='transaction-search'
          onKeyPress={this.handleKeyPress}
          className='form-control'
          placeholder={placeholder} value={searchTerm} />
        <span className='input-group-btn'>
          <button className='btn btn-outline-primary' onClick={this.handleSearchBtn}>Search</button>
        </span>
      </div>
    )
  }
}
