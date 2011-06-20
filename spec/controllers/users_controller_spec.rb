require 'spec_helper'

describe UsersController do
  render_views

  describe "GET 'index'" do
    context "for non-signed-in users" do
      it "should deny access" do
        get :index
        response.should redirect_to(signin_path)
        flash[:notice].should =~ /sign in/i
      end
    end

    context "for signed-in users" do
      let(:user) { Factory(:user) }
      let(:users) do
        users = [user]
      end

      before(:each) do
        test_sign_in(user)
        users << Factory(:user, :name => "Bob", :email => "another@example.com")
        users << Factory(:user, :name => "Ben", :email => "another@example.net")
        30.times do
          users << Factory(:user, :email => Factory.next(:email))
        end
        get :index
      end

      subject { response }

      it { should be_success }

      it { should have_selector("title", :content => "All users") }

      it "should have an element for each user" do
        users.each do |user|
          subject.should have_selector("li", :content => user.name)
        end
      end

      it "should have an element for each user" do
        users.each do |user|
          subject.should have_selector("li", :content => user.name)
        end
      end

      it "should paginate users" do
        subject.should have_selector("div.pagination")
        subject.should have_selector("span.disabled", :content => "Previous")
        subject.should have_selector("a", :href => "/users?page=2",
                                           :content => "2")
        subject.should have_selector("a", :href => "/users?page=2",
                                           :content => "Next")
      end

      it { should_not have_selector("a", :content => "delete") }
    end

    context "for admin users" do
      let(:admin) { Factory(:user, :email => "admin@example.com", :admin => true) }
      before(:each) do
        test_sign_in(admin)
        get :index
      end
      subject { response }

      it { should have_selector("a", :content => "delete") }
    end
  end

  describe "GET 'new'" do
    before { get 'new' }
    subject { response }

    it { should be_success }

    it { should have_selector("title", :content => "Sign up") }

    { name: "text", email: "text",
      password: "password", password_confirmation: "password" }.each do |field, type|
      it "should have a #{field} field" do
        subject.should have_selector("input[name='user[#{field}]'][type='#{type}']")
      end
    end

    context "for signed-in users" do
      let(:user) { Factory(:user) }
      before(:each) do
        test_sign_in(user)
        get :new
      end

      it { should redirect_to(root_path) }
    end
  end

  describe "POST 'create'" do
    context "success" do
      let(:attr) do
        { name: "New User", email: "user@example.com",
          password: "foobar", password_confirmation: "foobar" }
      end

      it "should create a user" do
        lambda do
          post :create, :user => attr
        end.should change(User, :count).by(1)
      end

      it "should sign the user in" do
        post :create, :user => attr
        controller.should be_signed_in
      end

      it "should redirect to the user show page" do
        post :create, :user => attr
        response.should redirect_to(user_path(assigns(:user)))
      end

      it "should have a welcome message" do
        post :create, :user => attr
        flash[:success].should =~ /welcome to the sample app/i
      end
    end

    context "failure" do
      let(:attr) do
        { name: "", email: "", password: "", password_confirmation: "" }
      end

      it "should not create a user" do
        lambda do
          post :create, user: attr
        end.should_not change(User, :count)
      end

      it "should have the right title" do
        post :create, user: attr
        response.should have_selector("title", content: "Sign up")
      end

      it "should render the 'new' page" do
        post :create, user: attr
        response.should render_template('new')
      end
    end

    context "for signed-in users" do
      let(:user) { Factory(:user) }
      let(:attr) do
        { name: user.name, email: user.email,
          password: user.password, password_confirmation: user.password_confirmation }
      end
      before(:each) { test_sign_in(user) }

      it "should redirect to the root url" do
        post :create, :user => attr
        response.should redirect_to(root_path)
      end
    end
  end

  describe "GET 'show'" do
    let(:user) { Factory(:user) }

    it "should show the user's microposts" do
      mp1 = Factory(:micropost, :user => user, :content => "Foo bar")
      mp2 = Factory(:micropost, :user => user, :content => "Baz quux")
      get :show, :id => user
      response.should have_selector("span.content", :content => mp1.content)
      response.should have_selector("span.content", :content => mp2.content)
    end
  end

  describe "GET 'edit'" do
    let(:user) { Factory(:user) }
    before(:each) do
      test_sign_in(user)
      get :edit, :id => user
    end
    subject { response }

    it { should be_success }

    it { should have_selector("title", :content => "Edit user") }

    it "should have the link to change the Gravatar" do
      gravatar_url = "http://gravatar.com/emails"
      subject.should have_selector("a", :href => gravatar_url,
                                    :content => "change")
    end
  end

  describe "PUT 'update'" do
    let(:user) { Factory(:user) }
    before(:each) { test_sign_in(user) }

    context "failure" do
      let(:attr) do
        { name: "", email: "", password: "", password_confirmation: "" }
      end
      before(:each) { put :update, :id => user, :user => attr }
      subject { response }

      it { should render_template('edit') }

      it { should have_selector("title", :content => "Edit user") }
    end

    context "success" do
      let(:attr) do
        { name: "New Name", email: "user@example.org",
          password: "barbaz", password_confirmation: "barbaz" }
      end
      before(:each) { put :update, :id => user, :user => attr }

      it "should change the user's attributes" do
        user.reload
        user.name.should  == attr[:name]
        user.email.should == attr[:email]
      end

      it "should redirect to the user show page" do
        response.should redirect_to(user_path(user))
      end

      it "should have a flash message" do
        flash[:success].should =~ /update/
      end
    end
  end

  describe "DELETE 'destroy'" do
    before(:each) do
      @user = Factory(:user)
    end

    context "as a non-signed-in user" do
      it "should deny access" do
        delete :destroy, :id => @user
        response.should redirect_to(signin_path)
      end
    end

    context "as a non-admin user" do
      it "should protect the page" do
        test_sign_in(@user)
        delete :destroy, :id => @user
        response.should redirect_to(root_path)
      end
    end

    context "as an admin user" do
      let(:admin) { Factory(:user, :email => "admin@example.com", :admin => true) }
      before(:each) do
        test_sign_in(admin)
      end

      it "should destroy the user" do
        lambda do
          delete :destroy, :id => @user
        end.should change(User, :count).by(-1)
      end

      it "should redirect to the user page" do
        delete :destroy, :id => @user
        response.should redirect_to(users_path)
      end

      it "shouldn't destroy themselves" do
        lambda do
          delete :destroy, :id => admin
        end.should_not change(User, :count)
      end
    end
  end

  describe "authentication of edit/update page" do
    let(:user) { Factory(:user) }

    context "for non-signed in users" do
      it "should deny access to 'edit'" do
        get :edit, :id => user
        response.should redirect_to(signin_path)
      end

      it "should deny access to 'update'" do
        put :update, :id => user, :user => {}
        response.should redirect_to(signin_path)
      end
    end

    context "for signed-in users" do
      before(:each) do
        wrong_user = Factory(:user, email: "user@example.com")
        test_sign_in(wrong_user)
      end

      it "should require matching users for 'edit'" do
        get :edit, :id => user
        response.should redirect_to(root_path)
      end

      it "should require matching users for 'update'" do
        put :update, :id => user, :user => {}
        response.should redirect_to(root_path)
      end
    end
  end

  describe "follow pages" do
    context "when not signed in" do
      it "should protect 'following'" do
        get :following, :id => 1
        response.should redirect_to(signin_path)
      end

      it "should protect 'followers'" do
        get :followers, :id => 1
        response.should redirect_to(signin_path)
      end
    end

    context "when signed in" do
      before(:each) do
        @user = test_sign_in(Factory(:user))
        @other_user = Factory(:user, :email => Factory.next(:email))
        @user.follow!(@other_user)
      end

      it "should show user following" do
        get :following, :id => @user
        response.should have_selector("a", :href => user_path(@other_user),
                                           :content => @other_user.name)
      end

      it "should show user followers" do
        get :followers, :id => @other_user
        response.should have_selector("a", :href => user_path(@user),
                                           :content => @user.name)
      end
    end
  end
end
