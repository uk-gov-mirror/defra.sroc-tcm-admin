require 'rails_helper'

RSpec.describe "regimes/show", type: :view do
  before(:each) do
    @regime = assign(:regime, Regime.create!(
      :name => "Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
  end
end
