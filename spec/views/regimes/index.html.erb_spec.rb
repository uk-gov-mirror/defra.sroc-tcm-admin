require 'rails_helper'

RSpec.describe "regimes/index", type: :view do
  before(:each) do
    assign(:regimes, [
      Regime.create!(
        :name => "Name"
      ),
      Regime.create!(
        :name => "Name"
      )
    ])
  end

  it "renders a list of regimes" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
  end
end
