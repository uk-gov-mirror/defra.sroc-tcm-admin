import React from 'react'

export default class OptionSelector extends React.Component {
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
    const name = this.props.name
    const id = this.props.id
    const label = this.props.label
    let labelControl = null
    if (label) {
      labelControl = (
        <label htmlFor={id} className='mr-2'>
          {label}
        </label>
      )
    }
    const clz = label ? 'form-group' : ''

    return (
      <div className={clz}>
        {labelControl}
        <select name={name}
          id={id}
          className={this.props.className}
          value={selectedValue}
          onChange={this.handleChange}>
          {this.buildOptions()}
        </select>
      </div>
    )
  }
}
