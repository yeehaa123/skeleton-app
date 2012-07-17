require 'spec_helper'

describe "Authentication" do
	before { visit signin_path }

	subject { page }

	describe "signin page" do

		it { should have_selector('h1', 	text: 'Sign in') }
		it { should have_selector('title', 	text: 'Sign in') }
	end

	describe "signin" do

		describe "with invalid information" do
			before { click_button "Sign in" }
			
			it { should have_selector('title', text: 'Sign in') }
			it { should have_error_message('Invalid') }

			describe "after visiting another page" do
				before { click_link "Home"}
				it { should_not have_error_message('Invalid') }
			end
		end

		describe "with valid information" do
			let(:user) { FactoryGirl.create(:user) }
 			before { sign_in user }

			it { should have_selector('title', 		text: user.name) }
			it { should have_link('Profile',		href: user_path(user)) }
			it { should have_link('Settings',		href: edit_user_path(user)) }
			it { should have_link('Sign out', 		href: signout_path) }
			it { should have_link('Users', 			href: users_path) }
			it { should_not have_link('Sign in', 	href: signin_path) }

			describe "followed by signout" do
				before { click_link "Sign out"}
				it { should have_link("Sign in") }
				it { should_not have_link('Profile',	href: user_path(user)) }
				it { should_not have_link('Settings',	href: edit_user_path(user)) }
				it { should_not have_link('Sign out', 	href: signout_path) }
				it { should_not have_link('Users', 		href: users_path) }
			end
		end
	end

	describe "authorization" do

		describe "for non-signed-in users" do
			let(:user) { FactoryGirl.create(:user) }
			
			describe "when attempting to visit a protected page" do
				before do
				  visit edit_user_path(user)
				  sign_in user
				end

				describe "after signing in" do
					it "should render the desired protected page" do
						page.should have_selector('title', text: 'Edit user') 
					end
				end

				describe "when signing in again" do
					before do
						click_link "Sign out"
						sign_in user
					end

					it "should render the default (profile) page" do
						page.should have_selector('title', text: user.name)
					end
				end
			end
			
			describe "in the Users controller" do

				describe "visiting the edit page" do
					before { visit edit_user_path(user) }
					it { should have_selector('title', text: 'Sign in') }
					it { should have_selector('div.alert.alert-notice') }
				end

				describe "submitting to the update action" do
					before { put user_path(user) }
					specify { response.should redirect_to(signin_path) }
				end

				describe "visiting the user index" do
					before { visit users_path }
					it { should have_selector('title', text: 'Sign in') }
				end
			end
		end

		describe "as wrong user" do
			let(:user) { FactoryGirl.create(:user) }
			let(:wrong_user) { FactoryGirl.create(:user, email: "wrong@example.com") }
			before { sign_in user }

			describe "visiting Users#edit page" do
				before { visit edit_user_path(wrong_user) }
				it { should_not have_selector('title', text: 'Edit user')}
			end

			describe "submitting a PUT request to the Users#update action" do
				before { put user_path(wrong_user) }
				specify { response.should redirect_to(root_path) }
			end
		end

		describe "as an non-admin user" do
			let(:user) { FactoryGirl.create(:user) }
			let(:non_admin) { FactoryGirl.create(:user) } 

			before { sign_in non_admin }

			describe "submitting a DELETE request to Users#destroy action" do
				before { delete user_path(user) }
				specify { response.should redirect_to(root_path) }
			end
		end

		describe "as any user" do
			let(:user) { FactoryGirl.create(:user) }
			before { sign_in user }

			describe "submitting a GET request to Users#new action" do
				before { get new_user_path }
				specify { response.should redirect_to(root_path) }
			end

			describe "submitting a POST request to Users#create action" do
				before { post users_path }			
				specify { response.should redirect_to(root_path) }
			end
		end

		describe "as an admin user" do
			let(:admin) { FactoryGirl.create(:admin) }

			before { sign_in admin }

			describe "submitting a DELETE request to admin#destroy action" do
				it "should not delete a user" do
					expect { delete user_path(admin) }.not_to change(User, :count)
				end
			end

			describe "DELETE request to admin#create should redirect" do
				before { delete user_path(admin) }			
				specify { response.should redirect_to(users_path) }
			end
		end
	end	
end