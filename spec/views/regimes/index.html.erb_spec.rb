require 'rails_helper'

RSpec.describe "regimes/index", type: :view do
  before(:each) do
    rs = []
    %w[ PAS CFD ].each do |n|
      r = Regime.new(name: n)
      r.save!
      rs << r.reload
    end

    assign(:regimes, rs)
  end

  it "renders a list of regimes" do
    render
    assert_select "tr>td", :text => "PAS"
    assert_select "tr>td", :text => "CFD"
  end
end
