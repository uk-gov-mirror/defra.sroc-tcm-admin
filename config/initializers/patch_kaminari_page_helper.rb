# frozen_string_literal: true

require "kaminari/helpers/tags"

module Kaminari
  module Helpers
    class Paginator < Tag
      class PageProxy
        def total_pages
          @options[:total_pages]
        end
      end
    end
  end
end
