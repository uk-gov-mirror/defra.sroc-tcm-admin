import React from 'react'
import Popover from 'react-simple-popover'

export default class ErrorPopup extends React.Component {
  constructor (props) {
    super(props)
    const open = !!this.props.open
    this.state = {
      open: open
    }
    this.handleClick = this.handleClick.bind(this)
    this.handleClose = this.handleClose.bind(this)
  }

  handleClick (ev) {
    console.log('click')
    ev.preventDefault()
    this.setState({open: !this.state.open})
  }

  handleClose (ev) {
    console.log('close')
    this.setState({open: false})
  }

  render () {
    const title = this.props.title
    const message = this.props.message
    const open = this.state.open

    return (
      <div>
        <a href='#' className='button' ref='target' onClick={this.handleClick}>
          <span className='oi oi-warning'></span>
        </a>
        <Popover
          title='A Title'
          placement='top'
          target={this.refs.target}
          show={open}
          onHide={this.handleClose}>
          <div>{message}</div>
        </Popover>
      </div>
    )
  }
}
