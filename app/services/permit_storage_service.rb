# frozen_string_literal: true

class PermitStorageService
  attr_reader :user, :regime

  def initialize(regime, user = nil)
    # when instantiated from a controller the 'current_user' should
    # be passed in. This will allow us to audit actions etc. down the line.
    @regime = regime
    @user = user
  end

  def search_all(fy, search, sort_col, sort_dir)
    q = all_for_financial_year(fy)
    q = q.search(search) unless search.blank?
    order_query(q, sort_col, sort_dir)
  end

  def all_for_financial_year(fy)
    regime.permit_categories.by_financial_year(fy)
    # t = PermitCategory.arel_table
    # regime.permit_categories.where(t[:valid_from].lteq(fy)).
    #   where(t[:valid_to].eq(nil).or(t[:valid_to].gt(fy)))
  end

  def active_for_financial_year(fy)
    all_for_financial_year(fy).active
  end

  def active_list_for_selection(fy)
    all_for_financial_year(fy).active.
      order("string_to_array(code, '.')::int[]")
  end

  def code_for_financial_year(code, fy)
    active_for_financial_year(fy).find_by(code: code)
  end

  def code_for_financial_year!(code, fy)
    active_for_financial_year(fy).find_by!(code: code)
  end

  def code_for_financial_year_with_any_status(code, fy)
    all_for_financial_year(fy).find_by(code: code)
  end

  def code_for_financial_year_with_any_status!(code, fy)
    all_for_financial_year(fy).find_by!(code: code)
  end

  def code_exists?(code)
    regime.permit_categories.exists?(code: code)
  end

  def permit_category_versions(code)
    regime.permit_categories.where(code: code).order(:valid_from)
  end

  def build_permit_category(code, description, valid_from,
                            status = 'active')
    regime.permit_categories.build(code: code,
                                  description: description,
                                  valid_from: valid_from,
                                  status: status)
  end

  def new_permit_category(code, description, valid_from, status = 'active')
    if code_exists?(code)
      update_or_create_new_version(code, description, valid_from, status)
    else
      # create excluded one from 1819 until the requested valid_from
      # unless valid_from is 1819
      pc = regime.permit_categories.create(code: code,
                                           description: description,
                                           valid_from: valid_from,
                                           status: status)
      if pc.valid? && valid_from != '1819'
        regime.permit_categories.create(code: code,
                                        description: description,
                                        valid_from: '1819',
                                        valid_to: valid_from,
                                        status: 'excluded')
      end 
      pc
    end
  end

  def find(code, fy)
    regime.permit_categories.find_by(code: code, valid_from: fy)
  end

  def update_or_create_new_version(code, description, fy, status = 'active')
    pc = regime.permit_categories.find_by(code: code, valid_from: fy)
    if pc.nil?
      # no version to update so create a new one
      add_permit_category_version(code, description, fy, status)
    else
      pc.description = description
      pc.status = status
      pc.save!
    end
    pc
  end

  def add_permit_category_version(code, description, valid_from, status = 'active')
    pc = nil
    pc_prev = nil
    pc_next = nil

    permit_category_versions(code).each do |c|
      if c.valid_from > valid_from
        pc_next = c
        break
      end
      pc_prev = c
    end

    PermitCategory.transaction do
      if pc_prev
        pc_prev.valid_to = valid_from
        pc_prev.save!
      end
      pc = new_permit_category(code, description, valid_from, status)
      if pc_next
        pc.valid_to = pc_next.valid_from
        pc.save!
      end
    end
    pc
  end

  # def update_permit_category_description(code, fy, description)
  #   # update a permit category description without creating a new version
  #   pc = code_for_financial_year_with_any_status!(code, fy)
  #   pc.description = description
  #   pc.save!
  # end

  def order_query(q, col, dir)
    dir = dir == 'desc' ? :desc : :asc

    if col.to_sym == :description
      q.order(description: dir)
    else
      q.order("string_to_array(code, '.')::int[] #{dir}")
    end
  end
end
