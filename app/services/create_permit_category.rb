# frozen_string_literal: true

class CreatePermitCategory < ServiceObject
  attr_reader :permit_category

  def initialize(params = {})
    super()
    @regime = params.fetch(:regime)
    @valid_from = params.fetch(:valid_from)
    @user = params.fetch(:user)
    @code = params.fetch(:code, nil)
    @description = params.fetch(:description, nil)
    @permit_category = nil
  end

  def call
    @result = create_category
    self
  end

  private

  def create_category
    @permit_category = @regime.permit_categories.build(code: @code,
                                                       description: @description,
                                                       valid_from: @valid_from,
                                                       status: "active")
    if code_exists?
      @permit_category.errors.add(:code, "^Code '#{@code}' is already in use.")
      false
    elsif @permit_category.save
      if @valid_from != "1819"
        @regime.permit_categories.create(code: @code,
                                         description: @description,
                                         valid_from: "1819",
                                         valid_to: @valid_from,
                                         status: "excluded")
      end
      true
    else
      false
    end
  end

  def code_exists?
    @regime.permit_categories.exists?(code: @code)
  end
end
