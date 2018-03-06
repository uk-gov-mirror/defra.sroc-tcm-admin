import React from 'react'

export default class RegionFilter extends React.Component {
  constructor (props) {
    super(props)
    this.handleChangeRegion = this.handleChangeRegion.bind(this)
  }

  buildRegionOptions () {
    const regions = this.props.regions
    return (regions.map((r) =>
      <option key={r.value} value={r.value}>{r.label}</option>
    ))
  }

  handleChangeRegion (ev) {
    this.props.onChangeRegion(ev.target.value)
  }

  render () {
    const selectedRegion = this.props.selectedRegion

    return (
      <div className='form-group'>
        <label htmlFor='region-select' className='mr-2'>Region</label>
        <select id='region-select' name='region'
          value={selectedRegion}
          className='form-control'
          onChange={this.handleChangeRegion}>
          {this.buildRegionOptions()}
        </select>
      </div>
    )
  }
}
