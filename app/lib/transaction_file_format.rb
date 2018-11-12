module TransactionFileFormat
  module Common
    RecordType          = 0
    SequenceNumber      = 1
  end

  module Header
    FileSource          = 2
    Region              = 3
    FileType            = 4
    FileSequenceNumber  = 5
    BillRunId           = 6
    FileDate            = 7
  end

  module Detail
    CustomerReference     = 2
    TransactionDate       = 3
    TransactionType       = 4
    TransactionReference  = 5
    RelatedReference      = 6
    CurrencyCode          = 7
    HeaderNarrative       = 8
    HeaderAttr1           = 9
    HeaderAttr2           = 10
    HeaderAttr3           = 11
    HeaderAttr4           = 12
    HeaderAttr5           = 13
    HeaderAttr6           = 14
    HeaderAttr7           = 15
    HeaderAttr8           = 16
    HeaderAttr9           = 17
    HeaderAttr10          = 18
    LineAmount            = 19
    LineVatCode           = 20
    LineAreaCode          = 21
    LineDescription       = 22
    LineIncomeStreamCode  = 23
    LineContextCode       = 24
    LineAttr1             = 25
    LineAttr2             = 26
    LineAttr3             = 27
    LineAttr4             = 28
    LineAttr5             = 29
    LineAttr6             = 30
    LineAttr7             = 31
    LineAttr8             = 32
    LineAttr9             = 33
    LineAttr10            = 34
    LineAttr11            = 35
    LineAttr12            = 36
    LineAttr13            = 37
    LineAttr14            = 38
    LineAttr15            = 39
    LineQuantity          = 40
    LineUnitOfMeasure     = 41
    LineUOMPrice          = 42
    # PAS extra fields
    Filename              = 43
    PermitReference       = 44
    OriginalPermitReference = 45
    AbsOriginalPermitReference = 46
    # Customer Name field
    PasCustomerName       = 47
    CfdCustomerName       = 44
    WmlCustomerName       = 10    # HeaderAttr2
  end

  module Trailer
    RecordCount           = 2
    DebitTotal            = 3
    CreditTotal           = 4
  end
end
