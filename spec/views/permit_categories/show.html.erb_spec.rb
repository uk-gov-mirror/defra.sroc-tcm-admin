require 'rails_helper'

RSpec.describe "permit_categories/show", type: :view do
  before(:each) do
    @permit_category = assign(:permit_category, PermitCategory.create!(
      :regime => "",
      :code => "Code",
      :description => "Description",
      :status => "Status",
      :display_order => 2
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Code/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/Status/)
    expect(rendered).to match(/2/)
  end
end
