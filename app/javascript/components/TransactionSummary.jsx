import React from 'react'

export default class TransactionSummary extends React.Component {
  constructor (props) {
    super(props)

    this.close = this.close.bind(this)
  }

  formattedPence (value) {
    return (value / 100.0).toLocaleString('en-GB', {
      style: 'currency', currency: 'GBP'
    })
  }

  close () {
    console.log('Closed modal')
    this.props.onClose()
  }

  componentDidMount () {
    $(this.dialog).on('hidden.bs.modal', this.close)
  }

  componentDidUpdate () {
    $(this.dialog).modal({
      show: this.props.show
    })
  }

  render () {
    const id = this.props.id
    const summary = this.props.summary
    const disabled = (summary.credit_count + summary.invoice_count === 0)
    const action = this.props.generateFilePath
    const region = this.props.region
    const csrfToken = this.props.csrfToken
    const title = this.props.title
    const buttonLabel = this.props.buttonLabel
    const excluded = summary.excluded_count

    let excludedWarning = null
    if (excluded > 0) {
      excludedWarning = (
        <div className='row alert alert-warning'>
          <div className='col'>
            Proceeding will remove <strong>{excluded}</strong> excluded transaction{excluded > 1 ? 's' : ''}
          </div>
        </div>
      )
    }

    return (
      <form method='post' action={action}>
        <input type='hidden' name='region' value={region}/>
        <input type='hidden' name='authenticity_token' value={csrfToken}/>
      <div id={id} className='modal fade' tabIndex='-1' role='dialog'
        data-backdrop='static' aria-hidden='true' ref={el => this.dialog = el}>
        <div className='modal-dialog' role='document'>
          <div className='modal-content'>
            <div className='modal-header'>
              <h5 className='modal-title'>{title}</h5>
              <button type='button' className='close' data-dismiss='modal'
                aria-label='Close'>
                <span aria-hidden='true'>&times;</span>
              </button>
            </div>
            <div className='modal-body'>
              <div className='row'>
                <div className='col'>
                  <p>Check the summary information before proceeding</p>
                </div>
              </div>
              <div className='row'>
                <div className='col'>
                  <div className='panel'>
                    <dl className='transaction-summary dl-horizontal'>
                      <dt>Number of credits</dt>
                      <dd>{ summary.credit_count }</dd>
                      <dt>Value of credits</dt>
                      <dd>{ this.formattedPence(summary.credit_total)}</dd>
                      <dt>Number of invoices</dt>
                      <dd>{ summary.invoice_count }</dd>
                      <dt>Value of invoices</dt>
                      <dd>{ this.formattedPence(summary.invoice_total) }</dd>
                      <dt>Net amount to be billed</dt>
                      <dd>{ this.formattedPence(summary.net_total) }</dd>
                    </dl>
                  </div>
                </div>
              </div>
              {excludedWarning}
            </div>
            <div className='modal-footer'>
              <input type='submit' className='btn btn-primary' disabled={disabled}
                value={buttonLabel} />
              <button type='button' className='btn btn-secondary'
                data-dismiss='modal'>
                Cancel
              </button>
            </div>
          </div>
        </div>
      </div>
    </form>
    )
  }
}
