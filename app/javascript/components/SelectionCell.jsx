import React from 'react'
import Select from 'react-select'
//import 'react-select/dist/react-select.css'

export default class SelectionCell extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      selectValue: this.props.value
    }
    this.onChange = this.onChange.bind(this)
  }

  onChange(val) {
    console.log('select changed [' + JSON.stringify(val) + ']')
    this.setState({selectValue: val}, () =>
      this.props.onChange(val)
    )
  }

  render() {
    const name = this.props.name
    const value = this.state.selectValue
    const options = this.props.options

    return (
      <Select name={name} value={value}
              options={options} onChange={this.onChange}
              clearable={true} simpleValue />
    )
  }
}
