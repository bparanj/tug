class ArticlesController < ApplicationController
  def index
    @articles = if params[:tag]
      Article.tagged_with(params[:tag])
    else
      Article.all
    end
  end

  def new
    @article = Article.new
  end

  def show
    @article = Article.find(params[:id])
  end
  
  def create
    @article = Article.new(article_params)
    if @article.save
      redirect_to @article, notice: 'Created article.'
    else
      render :new
    end
  end

  def edit
    @article = Article.find(params[:id])
  end
  
  def update
    @article = Article.find(params[:id])
    if @article.update_attributes(article_params)
      redirect_to @article, notice: 'Updated article.'
    else
      render :edit
    end
  end
  
  private
  
  def article_params
    params.require(:article).permit(:name, :published_on, :content, :tag_list)
  end
end
