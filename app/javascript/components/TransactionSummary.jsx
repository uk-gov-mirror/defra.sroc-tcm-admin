import React from 'react'

export default class TransactionSummary extends React.Component {
  constructor(props) {
    super(props)
  }

  formattedPence(value) {
    return (value / 100).toLocaleString('en-GB', {
      style: 'currency', currency: 'GBP'
    })
  }

  render() {
    const summary = this.props.summary

    return (
      <div className='row'>
        <div className='col'>
          <div className='panel'>
            <dl className='transaction-summary dl-horizontal'>
              <dt>Number of credits</dt>
              <dd>{ summary.credit_count }</dd>
              <dt>Value of credits</dt>
              <dd>{ this.formattedPence(summary.credit_total * -1)}</dd>
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
    )
  }
}
