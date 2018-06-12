'use strict'

const Constants = module.exports = {}

Constants.PAS_COLUMNS = { 
  unbilled: [
    {
      name: 'excluded',
      label: '',
      accessHelp: 'transaction for Permit ',
      accessHelpColumn: 'permit_reference',
      sortable: false,
      editable: true
    }, {
      name: 'original_filename',
      label: 'File Reference',
      sortable: true,
      editable: false
    }, {
      name: 'original_file_date',
      label: 'File Date',
      sortable: true,
      editable: false
    }, {
      name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      editable: false
    }, {
      name: 'permit_reference',
      label: 'Permit',
      sortable: true,
      editable: false
    }, {
      name: 'original_permit_reference',
      label: 'Original Permit',
      sortable: true,
      editable: false
    }, {
      name: 'sroc_category',
      label: 'SRoC Category',
      accessHelp: 'SRoC Category for Permit ',
      accessHelpColumn: 'permit_reference',
      sortable: true,
      editable: true
    }, {
      name: 'compliance_band',
      label: 'Compliance Band',
      sortable: true,
      editable: false
    }, {
      name: 'temporary_cessation',
      label: 'TC',
      accessLabel: 'Temporary Cessation',
      accessHelp: 'Temporary cessation flag for Permit ',
      accessHelpColumn: 'permit_reference',
      sortable: false,
      editable: true
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      editable: false
    }, {
      name: 'amount',
      label: 'Amount (£)',
      sortable: false,
      editable: false,
      rightAlign: true
    }
  ],
  historic: [
    { name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      editable: false
    }, {
      name: 'permit_reference',
      label: 'Permit',
      sortable: true,
      editable: false
    }, {
      name: 'original_permit_reference',
      label: 'Original Permit',
      sortable: true,
      editable: false
    }, {
      name: 'sroc_category',
      label: 'SRoC Category',
      sortable: true,
      editable: false
    }, {
      name: 'temporary_cessation',
      label: 'TC',
      accessLabel: 'Temporary Cessation',
      sortable: true,
      editable: false
    }, {
      name: 'compliance_band',
      label: 'Compliance Band',
      sortable: true,
      editable: false
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      editable: false
    }, {
      name: 'amount',
      label: 'Amount (£)',
      sortable: true,
      editable: false,
      rightAlign: true
    }, {
      name: 'original_filename',
      label: 'File (Src)',
      sortable: true,
      editable: false
    }, {
      name: 'generated_filename',
      label: 'File (TCM)',
      sortable: true,
      editable: false
    }, {
      name: 'generated_file_date',
      label: 'File Date (TCM)',
      sortable: true,
      editable: false
    }, {
      name: 'tcm_transaction_reference',
      label: 'Transaction Ref',
      accessLabel: 'Transaction Reference',
      sortable: true,
      editable: false
    }
  ],
  retrospective: [
    { name: 'original_filename',
      label: 'File Reference',
      sortable: true,
      editable: false
    }, {
      name: 'original_file_date',
      label: 'File Date',
      sortable: true,
      editable: false
    }, {
      name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      editable: false
    }, {
      name: 'permit_reference',
      label: 'Permit',
      sortable: true,
      editable: false
    }, {
      name: 'original_permit_reference',
      label: 'Original Permit',
      sortable: true,
      editable: false
    }, {
      name: 'compliance_band',
      label: 'Compliance Band',
      sortable: true,
      editable: false
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      editable: false
    }, {
      name: 'line_amount',
      label: 'Amount (£)',
      sortable: false,
      editable: false,
      rightAlign: true
    }
  ],
  excluded: [
    { name: 'original_filename',
      label: 'File Reference',
      sortable: true,
      editable: false
    }, {
      name: 'original_file_date',
      label: 'File Date',
      sortable: true,
      editable: false
    }, {
      name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      editable: false
    }, {
      name: 'permit_reference',
      label: 'Permit',
      sortable: true,
      editable: false
    }, {
      name: 'original_permit_reference',
      label: 'Original Permit',
      sortable: true,
      editable: false
    }, {
      name: 'compliance_band',
      label: 'Compliance Band',
      sortable: true,
      editable: false
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      editable: false
    }, {
      name: 'excluded_reason',
      label: 'Exclusion Reason',
      sortable: true,
      editable: false
    }, {
      name: 'amount',
      label: 'Credit/Invoice',
      sortable: false,
      editable: false,
      rightAlign: true
    }
  ]
}

Constants.CFD_COLUMNS = {
  unbilled: [
    {
      name: 'excluded',
      label: '',
      accessHelp: 'transaction for Consent Reference ',
      accessHelpColumn: 'consent_reference',
      sortable: false,
      editable: true
    }, {
      name: 'original_filename',
      label: 'File Reference',
      sortable: true,
      editable: false
    }, {
      name: 'original_file_date',
      label: 'File Date',
      sortable: true,
      editable: false
    }, {
      name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      editable: false
    }, {
      name: 'consent_reference',
      label: 'Consent',
      sortable: true,
      editable: false
    }, {
      name: 'version',
      label: 'Ver',
      accessLabel: 'Version',
      sortable: false,
      editable: false
    }, {
      name: 'discharge',
      label: 'Dis',
      accessLabel: 'Discharge',
      sortable: false,
      editable: false
    }, {
      name: 'sroc_category',
      label: 'SRoC Category',
      accessHelp: 'SRoC Category for Consent ',
      accessHelpColumn: 'consent_reference',
      sortable: true,
      editable: true
    }, {
      name: 'variation',
      label: '%',
      accessLabel: 'Variation Percentage',
      sortable: true,
      editable: false
    }, {
      name: 'temporary_cessation',
      label: 'TC',
      accessLabel: 'Temporary Cessation',
      accessHelp: 'Temporary cessation flag for Consent ',
      accessHelpColumn: 'consent_reference',
      sortable: false,
      editable: true
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      editable: false
    }, {
      name: 'amount',
      label: 'Amount (£)',
      sortable: false,
      editable: false,
      rightAlign: true
    }
  ],
  historic: [
    {
      name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      editable: false
    }, {
      name: 'consent_reference',
      label: 'Consent',
      sortable: true,
      editable: false
    }, {
      name: 'version',
      label: 'Ver',
      accessLabel: 'Version',
      sortable: true,
      editable: false
    }, {
      name: 'discharge',
      label: 'Dis',
      accessLabel: 'Discharge',
      sortable: true,
      editable: false
    }, {
      name: 'sroc_category',
      label: 'SRoC Category',
      sortable: true,
      editable: false
    }, {
      name: 'variation',
      label: '%',
      accessLabel: 'Variation Percentage',
      sortable: true,
      editable: false
    }, {
      name: 'temporary_cessation',
      label: 'TC',
      accessLabel: 'Temporary Cessation',
      sortable: true,
      editable: false
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      editable: false
    }, {
      name: 'amount',
      label: 'Amount (£)',
      sortable: true,
      editable: false,
      rightAlign: true
    }, {
      name: 'original_filename',
      label: 'File (Src)',
      sortable: true,
      editable: false
    }, {
      name: 'generated_filename',
      label: 'File (TCM)',
      sortable: true,
      editable: false
    }, {
      name: 'generated_file_date',
      label: 'File Date (TCM)',
      sortable: true,
      editable: false
    }, {
      name: 'tcm_transaction_reference',
      label: 'Transaction Ref',
      accessLabel: 'Transaction Reference',
      sortable: true,
      editable: false
    }
  ],
  retrospective: [
    { name: 'original_filename',
      label: 'File Reference',
      sortable: true,
      editable: false
    }, {
      name: 'original_file_date',
      label: 'File Date',
      sortable: true,
      editable: false
    }, {
      name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      editable: false
    }, {
      name: 'consent_reference',
      label: 'Consent',
      sortable: true,
      editable: false
    }, {
      name: 'version',
      label: 'Ver',
      accessLabel: 'Version',
      sortable: false,
      editable: false
    }, {
      name: 'discharge',
      label: 'Dis',
      accessLabel: 'Discharge',
      sortable: false,
      editable: false
    }, {
      name: 'variation',
      label: '%',
      accessLabel: 'Variation Percentage',
      sortable: true,
      editable: false
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      editable: false
    }, {
      name: 'line_amount',
      label: 'Amount (£)',
      sortable: false,
      editable: false,
      rightAlign: true
    }
  ],
  excluded: [
    { name: 'original_filename',
      label: 'File Reference',
      sortable: true,
      editable: false
    }, {
      name: 'original_file_date',
      label: 'File Date',
      sortable: true,
      editable: false
    }, {
      name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      editable: false
    }, {
      name: 'consent_reference',
      label: 'Consent',
      sortable: true,
      editable: false
    }, {
      name: 'version',
      label: 'Ver',
      accessLabel: 'Version',
      sortable: false,
      editable: false
    }, {
      name: 'discharge',
      label: 'Dis',
      accessLabel: 'Discharge',
      sortable: false,
      editable: false
    }, {
      name: 'variation',
      label: '%',
      accessLabel: 'Variation Percentage',
      sortable: true,
      editable: false
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      editable: false
    }, {
      name: 'excluded_reason',
      label: 'Exclusion Reason',
      sortable: true,
      editable: false
    }, {
      name: 'amount',
      label: 'Credit/Invoice',
      sortable: false,
      editable: false,
      rightAlign: true
    }
  ]
}

Constants.WML_COLUMNS = {
  unbilled: [
    {
      name: 'excluded',
      label: '',
      accessHelp: 'transaction for Permit ',
      accessHelpColumn: 'permit_reference',
      sortable: false,
      editable: true
    }, {
      name: 'original_filename',
      label: 'File Reference',
      sortable: true,
      editable: false
    }, {
      name: 'original_file_date',
      label: 'File Date',
      sortable: true,
      editable: false
    }, {
      name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      editable: false
    }, {
      name: 'permit_reference',
      label: 'Permit',
      sortable: true,
      editable: false
    }, {
      name: 'sroc_category',
      label: 'SRoC Category',
      accessHelp: 'SRoC Category for Permit ',
      accessHelpColumn: 'permit_reference',
      sortable: true,
      editable: true
    }, {
      name: 'compliance_band',
      label: 'Compliance Band',
      sortable: true,
      editable: false
    }, {
      name: 'temporary_cessation',
      label: 'TC',
      accessLabel: 'Temporary Cessation',
      accessHelp: 'Temporary cessation flag for Permit ',
      accessHelpColumn: 'permit_reference',
      sortable: false,
      editable: true
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      editable: false
    }, {
      name: 'amount',
      label: 'Amount (£)',
      sortable: false,
      editable: false,
      rightAlign: true
    }
  ],
  historic: [
    { name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      editable: false
    }, {
      name: 'permit_reference',
      label: 'Permit',
      sortable: true,
      editable: false
    }, {
      name: 'sroc_category',
      label: 'SRoC Category',
      sortable: true,
      editable: false
    }, {
      name: 'temporary_cessation',
      label: 'TC',
      accessLabel: 'Temporary Cessation',
      sortable: true,
      editable: false
    }, {
      name: 'compliance_band',
      label: 'Compliance Band',
      sortable: true,
      editable: false
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      editable: false
    }, {
      name: 'amount',
      label: 'Amount (£)',
      sortable: true,
      editable: false,
      rightAlign: true
    }, {
      name: 'original_filename',
      label: 'File (Src)',
      sortable: true,
      editable: false
    }, {
      name: 'generated_filename',
      label: 'File (TCM)',
      sortable: true,
      editable: false
    }, {
      name: 'generated_file_date',
      label: 'File Date (TCM)',
      sortable: true,
      editable: false
    }, {
      name: 'tcm_transaction_reference',
      label: 'Transaction Ref',
      accessLabel: 'Transaction Reference',
      sortable: true,
      editable: false
    }
  ],
  retrospective: [
    { name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      editable: false
    }, {
      name: 'permit_reference',
      label: 'Permit',
      sortable: true,
      editable: false
    }, {
      name: 'compliance_band',
      label: 'Compliance Band',
      sortable: true,
      editable: false
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      editable: false
    }, {
      name: 'amount',
      label: 'Amount (£)',
      sortable: false,
      editable: false,
      rightAlign: true
    }
  ],
  excluded: [
    { name: 'customer_reference',
      label: 'Customer',
      sortable: true,
      editable: false
    }, {
      name: 'permit_reference',
      label: 'Permit',
      sortable: true,
      editable: false
    }, {
      name: 'compliance_band',
      label: 'Compliance Band',
      sortable: true,
      editable: false
    }, {
      name: 'period',
      label: 'Period',
      sortable: true,
      editable: false
    }, {
      name: 'excluded_reason',
      label: 'Exclusion Reason',
      sortable: true,
      editable: false
    }, {
      name: 'amount',
      label: 'Credit/Invoice',
      sortable: false,
      editable: false,
      rightAlign: true
    }
  ]
}

Constants.DATA_FILE_COLUMNS = [
  { name: 'line_number',
    label: 'Line No',
    sortable: true,
    editable: false
  }, {
    name: 'message',
    label: 'Description',
    sortable: true,
    editable: false
  }
]

Constants.TRANSACTION_DOWNLOAD_LIMIT = 15000

Constants.VIEW_MODE_NAMES = [
  'unbilled',
  'historic',
  'retrospective',
  'excluded'
]

Constants.VIEW_MODES = {
  unbilled: {
    name: 'transactions',
    label: 'Transactions to be billed',
    path: '/transactions',
    summaryPath: '/transaction_summary',
    generatePath: '/transaction_files'
  },
  historic: {
    name: 'history',
    label: 'Transaction History',
    path: '/history'
  },
  retrospective: {
    name: 'retrospective',
    label: 'Retrospectives to be billed',
    path: '/retrospectives',
    summaryPath: '/retrospective_summary',
    generatePath: '/retrospective_files'
  },
  excluded: {
    name: 'excluded',
    label: 'Excluded transactions',
    path: '/exclusions'
  }//,
  // { name: 'retrospective_history',
  //   label: 'Retrospective History',
  //   path: '/retrospective_history'
  // }
}

// Constants.regimeColumns = (regime, history) => {
//   let cols = null
//   if (regime === 'pas') {
//     cols = Constants.INSTALLATIONS_COLUMNS
//   } else if (regime === 'cfd') {
//     cols = Constants.WATER_QUALITY_COLUMNS
//   } else if (regime === 'wml') {
//     cols = Constants.WASTE_COLUMNS
//   } else {
//     throw new Error('Unknown regime: ' + regime)
//   }
//
//   if (history) {
//     // if historic data the remove the editable flag to prevent modification
//     cols = cols.map(c => {
//       c.editable = false
//       return c
//     })
//   }
//
//   return cols
// }
