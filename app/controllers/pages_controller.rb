class PagesController < ApplicationController
  before_action :set_page, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy, :read, :all_read]
  before_action :set_user

  def index
    # ログイン有無により処理を分岐
    if !@user.id.nil?
      @pages = Page.favorited_pages(current_user)
                   .includes(:user).eager_load(:favorite).includes(:tags)
                   .page(params[:page])                                           
    else
      @pages = Page.all.includes(:user).includes(:favorite).includes(:tags)
                   .order('updated_at DESC').page(params[:page])
    end
  end

  def search
    @pages = Page.includes(:user).includes(:favorite).includes(:tags)
                 .search(params[:search_text])
    @pages = Kaminari.paginate_array(@pages).page(params[:page])    
    render :index
  end

  def show
    # comment_idが渡されていれば、既存のコメントを取得
    if params[:comment_id].blank?
      @comment = @page.comments.build
    else
      @comment = Comment.find(params[:comment_id])
    end
    # 最新のものから降順に取得
    @comments = Comment.where(page_id: params[:id])
                       .order('id DESC')
                       .page(params[:page]).per(5)
    increment_page_view(@page.id)
  end

  def new
    @page = Page.new
  end

  def edit
  end

  def create
    prepare_page_create
    if @page.save
      redirect_to @page, notice: notice_messages(:create)
      notice_page_info(@page)
    else
      render :new
    end
  end

  def update
    if @page.update(page_params)
      redirect_to @page, notice: notice_messages(:update)
    else
      render :edit
    end
  end

  def destroy
    @page.destroy
    redirect_to pages_url, notice: notice_messages(:destroy)
  end

  def read
    favorite = Favorite.find_by(page_id: params[:id], user_id: current_user.id)
    favorite.update(read: true)
    increment_page_view(favorite.page_id)
    redirect_to params[:url]
  end

  def all_read
    # ログインユーザーの全てのページを既読に更新
    Favorite.where(user_id: current_user.id).update_all(read: true)
    redirect_to pages_url
  end

  private

  def prepare_page_create
    @page = Page.new(page_params)
    @page.user_id = current_user.id
    @page.html = @page.get_html(@page.url)
    @page.page_update_date = DateTime.now
  end

  def set_user
    @user = current_user || User.new
  end

  def set_page
    @page = Page.find(params[:id])
  end

  def page_params
    params.require(:page).permit(:name, :url, :tag_list, :image_src)
  end

  def notice_page_info(page)
    message = <<~"EOS"
      Moookに新規ページが登録されました！
      名前：#{page.name}
      URL:#{page.url}
    EOS

    notice_slack(message)
  end

  def notice_messages(action)
    case action
    when :create  then '新しいページを登録しました。'
    when :update  then 'ページの情報を更新しました。'
    when :destroy then 'ページを削除しました。'
    end
  end

  def increment_page_view(page_id)
    page_view = PageView.find_or_initialize_by(page_id: page_id)
    page_view.page_view_count += 1
    page_view.save
  end
end
