# frozen_string_literal: true

class UsersController < StoreController
  skip_before_action :set_current_order, only: :show, raise: false
  prepend_before_action :authorize_actions, only: :new

  include Taxonomies

  def show
    load_object
    @orders = @user.orders.complete.order('completed_at desc')
  end

  def create
    @user = Spree::User.new(user_params)
    if @user.save

      if current_order
        session[:guest_token] = nil
      end

      redirect_back_or_default(root_url)
    else
      render :new
    end
  end

  def edit
    load_object
  end

  def update
    load_object
    if @user.update(user_params)
      spree_current_user.reload
      redirect_url = account_url

      if params[:user][:password].present?
        # this logic needed b/c devise wants to log us out after password changes
        if Spree::Auth::Config[:signout_after_password_change]
          redirect_url = login_url
        else
          bypass_sign_in(@user)
        end
      end
      redirect_to redirect_url, notice: I18n.t('spree.account_updated')
    else
      render :edit
    end
  end

  def confirm(args = {})
    pending_any_confirmation do
      if confirmation_period_expired?
        self.errors.add(:email, :confirmation_period_expired,
          period: Devise::TimeInflector.time_ago_in_words(self.class.confirm_within.ago))
        return false
      end

      self.confirmed_at = Time.now.utc

      saved = if pending_reconfirmation?
        skip_reconfirmation!
        self.email = unconfirmed_email
        self.unconfirmed_email = nil

        # We need to validate in such cases to enforce e-mail uniqueness
        save(validate: true)
      else
        save(validate: args[:ensure_valid] == true)
      end

      after_confirmation if saved
      saved
    end
  end

  private

  def user_params
    params.require(:user).permit(Spree::PermittedAttributes.user_attributes | [:email])
  end

  def load_object
    @user ||= Spree::User.find_by(id: spree_current_user&.id)
    authorize! params[:action].to_sym, @user
  end

  def authorize_actions
    authorize! params[:action].to_sym, Spree::User.new
  end

  def accurate_title
    I18n.t('spree.my_account')
  end
end
