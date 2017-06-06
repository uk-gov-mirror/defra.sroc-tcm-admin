require "rails_helper"

RSpec.describe RegimesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/regimes").to route_to("regimes#index")
    end

    it "routes to #new" do
      expect(:get => "/regimes/new").to route_to("regimes#new")
    end

    it "routes to #show" do
      expect(:get => "/regimes/1").to route_to("regimes#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/regimes/1/edit").to route_to("regimes#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/regimes").to route_to("regimes#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/regimes/1").to route_to("regimes#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/regimes/1").to route_to("regimes#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/regimes/1").to route_to("regimes#destroy", :id => "1")
    end

  end
end
