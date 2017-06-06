require 'rails_helper'

RSpec.describe "Regimes", type: :request do
  describe "GET /regimes" do
    it "works! (now write some real specs)" do
      get regimes_path
      expect(response).to have_http_status(200)
    end
  end
end
