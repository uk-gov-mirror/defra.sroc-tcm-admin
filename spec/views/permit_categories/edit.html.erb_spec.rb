require 'rails_helper'

RSpec.describe "permit_categories/edit", type: :view do
  before(:each) do
    @permit_category = assign(:permit_category, PermitCategory.create!(
      :regime => "",
      :code => "MyString",
      :description => "MyString",
      :status => "MyString",
      :display_order => 1
    ))
  end

  it "renders the edit permit_category form" do
    render

    assert_select "form[action=?][method=?]", permit_category_path(@permit_category), "post" do

      assert_select "input[name=?]", "permit_category[regime]"

      assert_select "input[name=?]", "permit_category[code]"

      assert_select "input[name=?]", "permit_category[description]"

      assert_select "input[name=?]", "permit_category[status]"

      assert_select "input[name=?]", "permit_category[display_order]"
    end
  end
end
