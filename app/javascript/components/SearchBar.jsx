import React from 'react'
import { RegionFilter } from './RegionFilter'
import { TransactionSearchBox } from './TransactionSearchBox'

export default class SearchBar extends React.Component {
  constructor(props) {
    super(props)

    this.onChangeRegion = this.onChangeRegion.bind(this)
    this.onSearch = this.onSearch.bind(this)
  }

  onChangeRegion(region) {
    this.props.onChangeRegion(region)
  }

  onSearch(term) {
    this.props.onSearch(term)
  }

  render() {
    const regions = this.props.regions
    const selectedRegion = this.props.selectedRegion
    const searchTerm = this.props.seachTerm
    const searchPlaceholder = this.props.searchPlaceholder

    return (
      <div className='row search-bar'>
        <div className='col mb-2 form-inline'>
          <RegionFilter regions={regions}
            selectedRegion={selectedRegion}
            onChangeRegion={this.onChangeRegion}
          />
          <TransactionSearchBox placeholder={searchPlaceholder}
            searchTerm={searchTerm} onSearch={this.onSearch}
          />
        </div>
      </div>
    )
  }
}
