require 'rails_helper'

RSpec.describe "permit_categories/index", type: :view do
  before(:each) do
    assign(:permit_categories, [
      PermitCategory.create!(
        :regime => "",
        :code => "Code",
        :description => "Description",
        :status => "Status",
        :display_order => 2
      ),
      PermitCategory.create!(
        :regime => "",
        :code => "Code",
        :description => "Description",
        :status => "Status",
        :display_order => 2
      )
    ])
  end

  it "renders a list of permit_categories" do
    render
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "Code".to_s, :count => 2
    assert_select "tr>td", :text => "Description".to_s, :count => 2
    assert_select "tr>td", :text => "Status".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
  end
end
