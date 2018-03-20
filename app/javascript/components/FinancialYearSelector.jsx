import React from 'react'

export default class FinancialYearSelector extends React.Component {
  constructor (props) {
    super(props)
    this.handleChange = this.handleChange.bind(this)
  }

  buildOptions () {
    const options = this.props.options
    if (options) {
      return (options.map((o, i) =>
        <option key={i} value={o.value}>{o.label}</option>
      ))
    }
  }

  handleChange (ev) {
    this.props.onChange(ev.target.value)
  }

  render () {
    const selectedValue = this.props.selectedValue

    return (
      <div className='form-group ml-4'>
        <label htmlFor='financial-year-select' className='mr-2'>FY</label>
        <select id='financial-year-select' name='financial-year'
          value={selectedValue}
          className='form-control'
          onChange={this.handleChange}>
          {this.buildOptions()}
        </select>
      </div>
    )
  }
}
