'use strict'

const Constants = module.exports = {}

Constants.INSTALLATIONS_COLUMNS = [
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
]

Constants.WATER_QUALITY_COLUMNS = [
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
    label: 'Version',
    sortable: false,
    selectable: false
  }, {
    name: 'discharge',
    label: 'Discharge',
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
]

Constants.WASTE_COLUMNS = [
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
]

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
