import React from 'react'

export default class ModeSelector extends React.Component {
  constructor (props) {
    super(props)
    this.handleChangeMode = this.handleChangeMode.bind(this)
  }

  buildModeOptions () {
    const modes = this.props.viewModes
    return (modes.map((r, i) =>
      <option key={i} value={i}>{r.label}</option>
    ))
  }

  handleChangeMode (ev) {
    this.props.onChangeMode(ev.target.value)
  }

  render () {
    const selectedMode = this.props.selectedMode

    return (
      <div className='form-group mr-4'>
        <label htmlFor='mode-select' className='mr-2'>View</label>
        <select id='mode-select' name='mode'
          value={selectedMode}
          className='form-control'
          onChange={this.handleChangeMode}>
          {this.buildModeOptions()}
        </select>
      </div>
    )
  }
}
