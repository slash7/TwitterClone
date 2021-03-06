require 'spec_helper'

describe UsersController do
  render_views
  
  describe "GET 'index'" do
    describe "for non-signed_in users" do
      it "should deny access" do
        get :index
        response.should redirect_to(signin_path)
        flash[:notice].should =~ /sign in/i
      end
    end
    describe "for signed-in users" do
      before(:each) do
        @user = test_sign_in(Factory(:user))
        second = Factory(:user, :email => "another@example.com")
        third = Factory(:user, :email => "another@example.org")
        @users = [@user, second, third]
        30.times do
          @users << Factory(:user, :email => Factory.next(:email))
        end
      end
      it "should be successful" do
        get :index
        response.should be_success
      end
      it "タイトルにAll users と表示されていること" do
        get :index
        response.should have_selector("title", :content => "All users")
      end
      it "ユーザ名一覧が表示されていること" do
        get :index
        @users.each do |u|
          response.should have_selector("li", :content => u.name)
        end
      end
      it "should have an element for each user" do
        get :index
        @users[0..2].each do |user|
          response.should have_selector("li", :content => user.name)
        end
      end
      it "should paginate users" do
        get :index
        response.should have_selector("div.pagination")
        response.should have_selector("span.disabled", :content => "Previous")
        response.should have_selector("a", :href => "/users?page=2", :content => "2")
        response.should have_selector("a", :href => "/users?page=2", :content => "Next")
      end
    end
  end
  
  describe "GET 'ユーザーが新規登録するとき'" do
    it "正しいタイトルが表示されること" do
      get 'new'
      response.should have_selector("title", :content => "Ruby on Rails Tutorial Sample App | Sign up")
    end

    it "名前フィールドが表示されること" do
      get :new
      response.should have_selector("input[name='user[name]'][type='text']")
    end

    it "正しくユーザー情報が保存されること" do
      #TODO:テストコードを書く。
    end
  end

  describe "GET 'ユーザーのつぶやきを閲覧するとき'" do
    before(:each) do
      @user = Factory(:user)
    end

    it "つぶやきページが表示されること" do
      get 'show', :id => @user
      response.should be_success
    end

    it "ユーザーが存在すること" do
      get 'show', :id => @user
      assigns(:user).should == @user
    end

    it "h1タグにユーザーの名前が表示されること" do
      get :show, :id => @user
      response.should have_selector("h1", :content => @user.name)
    end

    it "プロフィール画像が表示されること" do
      get :show, :id => @user
      response.should have_selector("h1>img", :class => "gravatar")
    end

    it "should show the user's microposts" do
      mp1 = Factory(:micropost, :user => @user, :content => "Foo bar")
      mp2 = Factory(:micropost, :user => @user, :content => "Baz quux")
      get :show, :id => @user
      response.should have_selector("span.content", :content => mp1.content)
      response.should have_selector("span.content", :content => mp2.content)
    end

    it "should paginate microposts" do
      35.times { Factory(:micropost, :user => @user, :content => "foo") }
      get :show, :id => @user
      response.should have_selector("div.pagination")
    end

    it "should display the micropost count" do
      10.times { Factory(:micropost, :user => @user, :content => "foo") }
      get :show, :id => @user
      response.should have_selector('td.sidebar',
                                    :content => @user.microposts.count.to_s)

    end
  end

  describe "POST '新規ユーザー作成するとき'" do
    
    describe "失敗するパターン" do
      
      before(:each) do
        @attr = {
          :name => "",
          :email => "",
          :password => "",
          :password_confirmation => ""
        }
      end
      
      it "ユーザー新規登録ができないこと" do
        lambda do
          post :create, :user => @attr
        end.should_not change(User, :count)
      end
      
      it "正しいタイトルが表示されること" do
        post :create, :user => @attr
        response.should have_selector("title", :content => "Sign up")
      end
      
      it "新規登録フォームが表示されること" do
        post :create, :user => @attr
        response.should render_template('new')
      end
    end
    
    describe "成功するパターン" do
      
      before(:each) do
        @attr = {
          :name => "New User",
          :email => "user@example.com",
          :password => "foobar",
          :password_confirmation => "foobar"
        }
      end
      
      it "ユーザーの新規登録ができること" do
        lambda do
          post :create, :user => @attr
        end.should change(User, :count).by(1)
      end
      
      it "つぶやきページが表示されること" do
        post :create, :user => @attr
        response.should redirect_to(root_path)
      end
      
      it "ウェルカムメッセージが表示されること" do
        post :create, :user => @attr
        flash[:success].should =~ /welcome to the sample app/i
      end
    end
  end
  
  describe "GET 'ユーザー情報を変更するとき'" do
    
    before(:each) do
      @user = Factory(:user)
      test_sign_in(@user)
    end
    
    it "ユーザー情報変更ページが表示されること" do
      get :edit, :id => @user
      response.should be_success
    end
    
    it "正しいタイトルが表示されること" do
      get :edit, :id => @user
      response.should have_selector("title", :content => "Edit user")
    end
    
    it "Gravatarリンクが変更されること" do
      get :edit, :id => @user
      gravatar_url = "http://gravatar.com/emails"
      response.should have_selector("a", :href => gravatar_url, :content => "change")
    end
  end
  
  describe "PUT 'ユーザー情報変更を確定するとき'" do
    
    before(:each) do
      @user = Factory(:user)
      test_sign_in(@user)
    end
    
    describe "失敗するパターン" do
      
      before(:each) do
        @invalid_attr = { :email => "", :name => "" }
      end
      
      it "ユーザー情報変更ページが表示されること" do
        put :update, :id => @user, :user => @invalid_attr
        response.should render_template('edit')
      end

      it "正しいタイトルが表示されること" do
        put :update, :id => @user, :user => @invalid_attr
        response.should have_selector("title", :content => "Edit user")
      end
    end
    
    describe "成功するパターン" do
      
      before(:each) do
        @attr = { :name => "New Name", :email => "user@example.org",
                        :password => "barbaz", :password_confirmation => "barbaz" }
      end
      
      it "ユーザー情報が変更されること" do
        put :update, :id => @user, :user => @attr
        user = assigns(:user)
        @user.reload
        @user.name.should == user.name
        @user.email.should == user.email
      end
      
      it "つぶやきページが表示されること" do
        put :update, :id => @user, :user => @attr
        response.should redirect_to(user_path(@user))
      end
      
      it "変更メッセージが表示されること" do
        put :update, :id => @user, :user => @attr
        flash[:success].should =~ /updated/
      end
    end
  end
  
  describe "ユーザー情報変更、更新ページを直接表示したとき" do
    
    before(:each) do
      @user = Factory(:user)
    end
    
    describe "ログインしていないユーザーの場合" do
      
      it "ユーザー情報変更ページにアクセスできないこと" do
        get :edit, :id => @user
        response.should redirect_to(signin_path)
      end
      
      it "ユーザー情報の更新ができないこと" do
        put :update, :id => @user, :user => {}
        response.should redirect_to(signin_path)
      end
    end
    
    describe "ログインしているユーザーの場合" do
      
      before(:each) do
        wrong_user = Factory(:user, :email => "user@example.net")
        test_sign_in(wrong_user)
      end
      
      it "メールアドレスが不正の場合、ユーザー情報変更ページにアクセスできないこと" do
        get :edit, :id => @user
        response.should redirect_to(root_path)
      end
      
      it "メールアドレスが不正の場合、ユーザー情報の更新ができないこと" do
        get :update, :id => @user, :user => {}
        response.should redirect_to(root_path)
      end
    end
  end
  
  describe "DELETE 'destroy'" do
    before(:each) do
      @user = Factory(:user)
    end
    
    describe "as a non-signed-in user" do
      it "should deny access" do
        delete :destroy, :id => @user
        response.should redirect_to(signin_path)
      end
    end
    
    describe "as a non-admin user" do
      it "should protect the page" do
        test_sign_in(@user)
        delete :destroy, :id => @user
        response.should redirect_to(root_path)
      end
    end
    
    describe "as an admin user" do
      before(:each) do
        admin = Factory(:user, :email => "admin@example.com", :admin => true)
        test_sign_in(admin)
      end
      
      it "should destroy the user" do
        lambda do
          delete :destroy, :id => @user
        end.should change(User, :count).by(-1)
      end
      
      it "should redirect to the users page" do
        delete :destroy, :id => @user
        response.should redirect_to(users_path)
      end
    end
  end
  
  describe "follow pages" do
    describe "when not signed in" do
      it "should protect 'following'" do
        get :following, :id => 1
        response.should redirect_to(signin_path)
      end
      
      it "should protect 'followers'" do
        get :followers, :id => 1
        response.should redirect_to(signin_path)
      end
    end
    
    describe "when signed in" do
      before(:each) do
        @user = test_sign_in(Factory(:user))
        @other_user = Factory(:user, :email => Factory.next(:email))
        @user.follow!(@other_user)
      end
      
      it "should show user following" do
        get :following, :id => @user
        response.should have_selector("a", :href => user_path(@other_user), :content => @other_user.name )
      end
      
      it "should show user followers" do
        get :followers, :id => @other_user
        response.should have_selector("a", :href => user_path(@user), :content => @user.name)
      end
    end
  end
end
