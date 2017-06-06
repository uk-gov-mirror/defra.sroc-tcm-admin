require 'rails_helper'

RSpec.describe "regimes/new", type: :view do
  before(:each) do
    assign(:regime, Regime.new(
      :name => "MyString"
    ))
  end

  it "renders new regime form" do
    render

    assert_select "form[action=?][method=?]", regimes_path, "post" do

      assert_select "input[name=?]", "regime[name]"
    end
  end
end
