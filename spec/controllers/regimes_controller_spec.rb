require 'rails_helper'

RSpec.describe RegimesController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # Regime. As you add validations to Regime, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    { name: "PAS" }
  }

  let(:invalid_attributes) {
    { name: "" }
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # RegimesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "returns a success response" do
      regime = Regime.create! valid_attributes
      get :index, params: {}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      regime = Regime.create! valid_attributes
      get :show, params: {id: regime.to_param}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      regime = Regime.create! valid_attributes
      get :edit, params: {id: regime.to_param}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Regime" do
        expect {
          post :create, params: {regime: valid_attributes}, session: valid_session
        }.to change(Regime, :count).by(1)
      end

      it "redirects to the created regime" do
        post :create, params: {regime: valid_attributes}, session: valid_session
        expect(response).to redirect_to(Regime.last)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: {regime: invalid_attributes}, session: valid_session
        expect(response).to be_success
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        { name: "WABS" }
      }

      it "updates the requested regime" do
        regime = Regime.create! valid_attributes
        put :update, params: {id: regime.to_param, regime: new_attributes}, session: valid_session
        regime.reload
        expect(regime.name).to eq(new_attributes[:name])
      end

      it "redirects to the regime" do
        regime = Regime.create! valid_attributes
        put :update, params: {id: regime.to_param, regime: valid_attributes}, session: valid_session
        expect(response).to redirect_to(regime)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        regime = Regime.create! valid_attributes
        put :update, params: {id: regime.to_param, regime: invalid_attributes}, session: valid_session
        expect(response).to be_success
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested regime" do
      regime = Regime.create! valid_attributes
      expect {
        delete :destroy, params: {id: regime.to_param}, session: valid_session
      }.to change(Regime, :count).by(-1)
    end

    it "redirects to the regimes list" do
      regime = Regime.create! valid_attributes
      delete :destroy, params: {id: regime.to_param}, session: valid_session
      expect(response).to redirect_to(regimes_url)
    end
  end

end
