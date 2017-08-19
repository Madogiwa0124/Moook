class PagesController < ApplicationController
  before_action :set_page, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  def index
    @pages = Page.favorited_pages(current_user)
    @favorites = Favorite.find_by(user_id: current_user.id)
  end

  def search
    @pages = Page.search(params[:search_text])
    render 'index'
  end

  def show
  end

  def new
    @page = Page.new
  end

  def edit
  end

  def create
    @page = Page.new(page_params)
    @page.user_id = current_user.id
    @page.html = @page.get_html(@page.url)
    if @page.save
      redirect_to @page, notice: '新しいページを登録しました。'
    else
      render :new
    end
  end

  def update
    if @page.update(page_params)
      redirect_to @page, notice: 'ページの情報を更新しました。' 
    else
      render :edit
    end
  end

  def destroy
    @page.destroy
    redirect_to pages_url, notice: 'ページを削除しました。'
  end

  def read
    binding.pry
    favorite = Favorite.find_by(page_id: params[:id], user_id: current_user.id)
    favorite.read = true
    favorite.save
    redirect_to params[:url]
  end

  private
    def set_page
      @page = Page.find(params[:id])
    end

    def page_params
      params.require(:page).permit(:name, :url, :tag_list)
    end
end
