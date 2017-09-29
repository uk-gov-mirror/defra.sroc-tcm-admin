require 'rails_helper'

RSpec.describe "permit_categories/new", type: :view do
  before(:each) do
    assign(:permit_category, PermitCategory.new(
      :regime => "",
      :code => "MyString",
      :description => "MyString",
      :status => "MyString",
      :display_order => 1
    ))
  end

  it "renders new permit_category form" do
    render

    assert_select "form[action=?][method=?]", permit_categories_path, "post" do

      assert_select "input[name=?]", "permit_category[regime]"

      assert_select "input[name=?]", "permit_category[code]"

      assert_select "input[name=?]", "permit_category[description]"

      assert_select "input[name=?]", "permit_category[status]"

      assert_select "input[name=?]", "permit_category[display_order]"
    end
  end
end
