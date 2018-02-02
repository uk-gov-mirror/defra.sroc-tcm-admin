class UsersController < AdminController
  before_action :set_user, only: [:show, :edit, :update, :reinvite]

  def index
    @users = User.order(:last_name)
  end

  def show
  end

  def new
    @user = User.new
    build_regimes
  end

  def create
    p = user_params.merge(password: Devise.friendly_token.first(8) + 'Az9')
    @user = User.create(p)

    if @user.valid?
      #invite the user
      invite_user(@user)
      redirect_to users_path, notice: 'User account created'
    else
      render :new
    end
  end

  def edit
    build_regimes
  end

  def update
    if @user.update(user_params)
      redirect_to users_path, notice: 'User account updated'
    else
      render :edit
    end
  end

  def reinvite
    invite_user(@user)
    redirect_to edit_user_path(@user)
  end

private
  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :password,
                                 :enabled, :role,
                                 regime_users_attributes: [:id, :regime_id, :enabled])
  end

  def build_regimes
    Regime.order(:title).each do |regime|
      @user.regime_users.find_or_initialize_by(regime_id: regime.id)
    end
  end

  def invite_user(user)
    user.invite!(current_user) do |u|
      u.skip_invitation = true
    end
    # invitation token not persisted (or serialized?) so need to grab it now
    invitation_link = accept_user_invitation_url(
      invitation_token: user.raw_invitation_token
    )
    UserMailer.invitation(user.email, user.full_name, invitation_link).deliver_later
    user.update_attributes(invitation_sent_at: Time.now.utc)
  end
end
