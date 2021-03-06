require 'spec_helper'

describe Admin::CategoriesController do
  
  describe "Not Logged in users" do
    describe "GET index" do
      it "redirects to the login page" do
        get :index
        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end
  end
  
  describe "Logged in users" do
    before (:each) do
      @request.env["devise.mapping"] = Devise.mappings[:admin_user]
      @user = FactoryGirl.create(:admin_user)
      @role = FactoryGirl.create(:role_admin)
      @user.roles << @role
      sign_in @user
    end
    
    describe "Existing Category" do
      before (:each) do
        @category = FactoryGirl.create(:category)
      end
      describe "GET index" do
        it "Should Show @categories array" do
          get :index
          expect(assigns(:categories)).to eq([@category])
        end
      end
      describe "GET show" do
        it "Should Show @category" do
          get :show, id: @category.id
          expect(assigns(:category)).to eq(@category)
        end
      end
      describe "GET edit" do
        it "Should have @category" do
          get :edit, id: @category.id
          expect(assigns(:category)).to eq(@category)
        end
        it "Should have @category not as new record" do
          get :edit, id: @category.id
          expect(assigns(:category)).not_to be_new_record
        end
      end
    end

    describe "New Category Record" do
      describe "GET new" do
        it "Should show new category page" do
          get :new
          expect(assigns(:category)).not_to be_nil
        end
        it "Should show new category page" do
          get :new
          expect(assigns(:category)).to be_new_record
        end
      end
    end
    
  end
end
