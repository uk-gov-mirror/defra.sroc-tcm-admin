require 'rails_helper'

RSpec.describe "regimes/edit", type: :view do
  before(:each) do
    @regime = assign(:regime, Regime.create!(
      :name => "MyString"
    ))
  end

  it "renders the edit regime form" do
    render

    assert_select "form[action=?][method=?]", regime_path(@regime), "post" do

      assert_select "input[name=?]", "regime[name]"
    end
  end
end
