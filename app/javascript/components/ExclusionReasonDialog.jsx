import React from 'react'
import OptionSelector from './OptionSelector'

export default class ExclusionReasonDialog extends React.Component {
  constructor (props) {
    super(props)

    this.state = {
      callbackFired: false
    }
    this.close = this.close.bind(this)
    this.onCancel = this.onCancel.bind(this)
    this.onChangeReason = this.onChangeReason.bind(this)
    this.onExcludeTransaction = this.onExcludeTransaction.bind(this)
  }

  onChangeReason (ev) {
    const val = ev.target.value
    // triggering re-rendering breaks something between the DOM and react
    // and you cannot close the dialog
    // ... so we don't set a state value here
  }

  onExcludeTransaction () {
    const reason = $(this.reasonSelect).val()
    $(this.dialog).off('hide.bs.modal', this.onCancel)
    $(this.dialog).modal('hide')
    $(this.dialog).on('hide.bs.modal', this.onCancel)
    this.props.onSave(reason)
  }

  onCancel (ev) {
    if (ev.type === 'hide') {
      this.props.onClose()
    } else {
      $(this.dialog).modal('hide')
    }
  }

  close () {
    $(this.dialog).modal('hide')
    this.props.onClose()
  }

  componentDidMount () {
    $(this.dialog).on('hide.bs.modal', this.onCancel)
  }

  componentWillUnmount () {
    $(this.dialog).off('hide.bs.modal', this.onCancel)
  }

  componentDidUpdate () {
    $(this.dialog).modal({
      show: this.props.show
    })
  }

  render () {
    const id = this.props.id
    const reasons = this.props.reasons
    const title = this.props.title
    const buttonLabel = this.props.buttonLabel
    const disabled = reasons.length === 0

    const options = reasons.map((item, i) => {
      return (<option key={i} value={item.reason}>{item.reason}</option>)
    })

    return (
      <div id={id} className='modal fade' tabIndex='-1' role='dialog'
        data-backdrop='static' aria-hidden='true' ref={el => this.dialog = el}>
        <div className='modal-dialog' role='document'>
          <div className='modal-content'>
            <div className='modal-header'>
              <h5 className='modal-title'>{title}</h5>
              <button type='button' className='close'
                onClick={this.onCancel}
                aria-label='Close'>
                <span aria-hidden='true'>&times;</span>
              </button>
            </div>
            <div className='modal-body'>
              <div className='row'>
                <div className='col'>
                  <h6 className='heading-small' id='reason-label'>
                    Select the reason for excluding this transaction
                  </h6>
                </div>
              </div>
              <div className='row'>
                <div className='col'>
                  <div className='panel'>
                    <select
                      ref={el => this.reasonSelect = el}
                      className='form-control'
                      name='reason-selector'
                      id='reason-selector'
                      aria-labelledby='reason-label'
                      onChange={this.onChangeReason}
                    >
                      {options}
                    </select>
                  </div>
                </div>
              </div>
            </div>
            <div className='modal-footer'>
              <button className='btn btn-primary'
                ref={el => this.saveBtn = el}
                disabled={disabled}
                onClick={this.onExcludeTransaction}>
                Exclude Transaction
              </button>
              <button type='button' className='btn btn-secondary'
                onClick={this.onCancel}>
                Cancel
              </button>
            </div>
          </div>
        </div>
      </div>
    )
  }
}
