require 'spec_helper'

describe PagesController do
  render_views

  let(:base_title) { "Ruby on Rails Tutorial Sample App " }

  describe "GET 'home'" do
    context "when not signed in" do
      before(:each) do
        get :home
      end
      subject do
        response
      end

      it { should be_success }
      it { should have_selector("title", :content => base_title + "| Home") }
    end

    context "when signed in" do
      before(:each) do
        @user = test_sign_in(Factory(:user))
        other_user = Factory(:user, :email => Factory.next(:email))
        other_user.follow!(@user)
      end

      it "should have the right micropost count" do
        regexes = [/0 microposts/, /1 micropost(?!s)/, /2 microposts/]
        regexes.each do |regex|
          get 'home'
          response.should have_selector("span.microposts") do |micropost_count|
            micropost_count.should contain(regex)
          end
          Factory(:micropost, :user => @user, :content => "Foo bar")
        end
      end

      it "should have the right following/followers counts" do
        get :home
        response.should have_selector("a", :href => following_user_path(@user),
                                           :content => "0 following")
        response.should have_selector("a", :href => followers_user_path(@user),
                                           :content => "1 follower")
      end
    end
  end

  describe "GET 'contact'" do
    it "should be successful" do
      get 'contact'
      response.should be_success
    end

    it "should have the right title" do
      get 'contact'
      response.should have_selector("title",
                        :content => base_title + "| Contact")
    end
  end

  describe "GET 'about'" do
    it "should be successful" do
      get 'about'
      response.should be_success
    end

    it "should have the right title" do
      get 'about'
      response.should have_selector("title",
                        :content => base_title + "| About")
    end
  end

  describe "GET 'help'" do
    it "shhould be successful" do
      get 'help'
      response.should be_success
    end

    it "should have the right title" do
      get 'help'
      response.should have_selector("title",
                        :content => base_title + "| Help")
    end
  end
end
