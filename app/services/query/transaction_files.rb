module Query
  class TransactionFiles < QueryObject
    def initialize(opts = {})
      @regime = opts.fetch(:regime)
      @region = opts.fetch(:region, '')
      @mode = opts.fetch(:mode, 'post')
      @sort_column = opts.fetch(:sort, :customer_reference)
      @sort_direction = opts.fetch(:sort_direction, 'asc')
      @search = opts.fetch(:search, '')
    end

    def call
      q = @regime.transaction_files
      q = pre_or_post_sroc(q)
      q = q.region(@region) unless @region.blank? || @region == 'all'
      q = q.search(@search) unless @search.blank?
      # SortTransactions.call(regime: @regime,
      #                       query: q,
      #                       sort: @sort_column,
      #                       sort_direction: @sort_direction)
    end

    private

    def pre_or_post_sroc(q)
      if @mode == 'pre'
        q.pre_sroc
      else
        q.post_sroc
      end
    end
  end
end
