'use strict'

const Constants = module.exports = {}

Constants.PAS_COLUMNS = { 
  '0': [
    { name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      selectable: false
    }, {
      name: 'permit_reference',
      label: 'Permit',
      sortable: true,
      selectable: false
    }, {
      name: 'original_permit_reference',
      label: 'Original Permit',
      sortable: true,
      selectable: false
    }, {
      name: 'sroc_category',
      label: 'SRoC Category',
      sortable: true,
      selectable: true
    }, {
      name: 'compliance_band',
      label: 'Compliance Band',
      sortable: true,
      selectable: false
    }, {
      name: 'temporary_cessation',
      label: 'TC',
      sortable: false,
      selectable: false
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      selectable: false
    }, {
      name: 'amount',
      label: 'Amount (£)',
      sortable: false,
      selectable: false,
      rightAlign: true
    }
  ],
  '1': [
    { name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      selectable: false
    }, {
      name: 'permit_reference',
      label: 'Permit',
      sortable: true,
      selectable: false
    }, {
      name: 'original_permit_reference',
      label: 'Original Permit',
      sortable: true,
      selectable: false
    }, {
      name: 'sroc_category',
      label: 'SRoC Category',
      sortable: true,
      selectable: false
    }, {
      name: 'compliance_band',
      label: 'Compliance Band',
      sortable: true,
      selectable: false
    }, {
      name: 'temporary_cessation',
      label: 'TC',
      sortable: false,
      selectable: false
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      selectable: false
    }, {
      name: 'amount',
      label: 'Amount (£)',
      sortable: false,
      selectable: false,
      rightAlign: true
    }
  ]
}

Constants.CFD_COLUMNS = {
  '0': [
    { name: 'original_filename',
      label: 'File Reference',
      sortable: true,
      selectable: false
    }, {
      name: 'original_file_date',
      label: 'File Date',
      sortable: true,
      selectable: false
    }, {
      name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      selectable: false
    }, {
      name: 'consent_reference',
      label: 'Consent',
      sortable: true,
      selectable: false
    }, {
      name: 'version',
      label: 'Ver',
      sortable: false,
      selectable: false
    }, {
      name: 'discharge',
      label: 'Dis',
      sortable: false,
      selectable: false
    }, {
      name: 'sroc_category',
      label: 'SRoC Category',
      sortable: true,
      selectable: true
    }, {
      name: 'variation',
      label: '%',
      sortable: true,
      selectable: false
    }, {
      name: 'temporary_cessation',
      label: 'TC',
      sortable: false,
      selectable: false
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      selectable: false
    }, {
      name: 'amount',
      label: 'Amount (£)',
      sortable: false,
      selectable: false,
      rightAlign: true
    }
  ],
  '1': [
    {
      name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      selectable: false
    }, {
      name: 'consent_reference',
      label: 'Consent',
      sortable: true,
      selectable: false
    }, {
      name: 'version',
      label: 'Ver',
      sortable: true,
      selectable: false
    }, {
      name: 'discharge',
      label: 'Dis',
      sortable: true,
      selectable: false
    }, {
      name: 'sroc_category',
      label: 'SRoC Category',
      sortable: true,
      selectable: false
    }, {
      name: 'variation',
      label: '%',
      sortable: true,
      selectable: false
    }, {
      name: 'temporary_cessation',
      label: 'TC',
      sortable: true,
      selectable: false
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      selectable: false
    }, {
      name: 'amount',
      label: 'Amount (£)',
      sortable: true,
      selectable: false,
      rightAlign: true
    }, {
      name: 'original_filename',
      label: 'File (Src)',
      sortable: true,
      selectable: false
    }, {
      name: 'generated_filename',
      label: 'File (TCM)',
      sortable: true,
      selectable: false
    }, {
      name: 'tcm_transaction_reference',
      label: 'Transaction Ref',
      sortable: true,
      selectable: false
    }
  ]
}

Constants.WML_COLUMNS = {
  '0': [
    { name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      selectable: false
    }, {
      name: 'permit_reference',
      label: 'Permit',
      sortable: true,
      selectable: false
    }, {
      name: 'sroc_category',
      label: 'SRoC Category',
      sortable: true,
      selectable: true
    }, {
      name: 'compliance_band',
      label: 'Compliance Band',
      sortable: true,
      selectable: false
    }, {
      name: 'temporary_cessation',
      label: 'TC',
      sortable: false,
      selectable: false
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      selectable: false
    }, {
      name: 'amount',
      label: 'Amount (£)',
      sortable: false,
      selectable: false,
      rightAlign: true
    }
  ],
  '1': [
    { name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      selectable: false
    }, {
      name: 'permit_reference',
      label: 'Permit',
      sortable: true,
      selectable: false
    }, {
      name: 'sroc_category',
      label: 'SRoC Category',
      sortable: true,
      selectable: false
    }, {
      name: 'compliance_band',
      label: 'Compliance Band',
      sortable: true,
      selectable: false
    }, {
      name: 'temporary_cessation',
      label: 'TC',
      sortable: false,
      selectable: false
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      selectable: false
    }, {
      name: 'amount',
      label: 'Amount (£)',
      sortable: false,
      selectable: false,
      rightAlign: true
    }
  ]
}

Constants.DATA_FILE_COLUMNS = [
  { name: 'line_number',
    label: 'Line No',
    sortable: true,
    selectable: false
  }, {
    name: 'message',
    label: 'Description',
    sortable: true,
    selectable: false
  }
]

Constants.VIEW_MODES = [
  { name: 'transactions',
    label: 'Transactions to be billed',
    path: '/transactions'
  },
  { name: 'history',
    label: 'Transaction History',
    path: '/history'
  }//,
  // { name: 'retrospective',
  //   label: 'Retrospectives to be billed',
  //   path: '/retrospectives'
  // },
  // { name: 'retrospective_history',
  //   label: 'Retrospective History',
  //   path: '/retrospective_history'
  // }
]

Constants.regimeColumns = (regime, history) => {
  let cols = null
  if (regime === 'pas') {
    cols = Constants.INSTALLATIONS_COLUMNS
  } else if (regime === 'cfd') {
    cols = Constants.WATER_QUALITY_COLUMNS
  } else if (regime === 'wml') {
    cols = Constants.WASTE_COLUMNS
  } else {
    throw new Error('Unknown regime: ' + regime)
  }

  if (history) {
    // if historic data the remove the selectable flag to prevent modification
    cols = cols.map(c => {
      c.selectable = false
      return c
    })
  }

  return cols
}
