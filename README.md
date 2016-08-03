Tagging from Scratch in Rails 5

In this article, you will learn how to tag just one model in your Rails 5 app from scratch.

Create a new Rails 5 app.

```
rails new tug
```

Create an article model.

```
rails g model article name published_on:date content:text
```

Create sample data in seeds.rb:

```ruby
batman = Article.create! name: "Batman", content: <<-ARTICLE
Batman is a fictional character created by the artist Bob Kane and writer Bill Finger. A comic book superhero, Batman first appeared in Detective Comics #27 (May 1939), and since then has appeared primarily in publications by DC Comics. Originally referred to as "The Bat-Man" and still referred to at times as "The Batman", he is additionally known as "The Caped Crusader", "The Dark Knight", and the "World's Greatest Detective," among other titles. (from Wikipedia)
ARTICLE

superman = Article.create! name: "Superman", content: <<-ARTICLE
Superman is a fictional comic book superhero appearing in publications by DC Comics, widely considered to be an American cultural icon. Created by American writer Jerry Siegel and Canadian-born American artist Joe Shuster in 1932 while both were living in Cleveland, Ohio, and sold to Detective Comics, Inc. (later DC Comics) in 1938, the character first appeared in Action Comics #1 (June 1938) and subsequently appeared in various radio serials, television programs, films, newspaper strips, and video games. (from Wikipedia)
ARTICLE

krypton = Article.create! name: "Krypton", content: <<-ARTICLE
Krypton is a fictional planet in the DC Comics universe, and the native world of the super-heroes Superman and, in some tellings, Supergirl and Krypto the Superdog. Krypton has been portrayed consistently as having been destroyed just after Superman's flight from the planet, with exact details of its destruction varying by time period, writers and franchise. Kryptonians were the dominant people of Krypton. (from Wikipedia)
ARTICLE

lex_luthor = Article.create! name: "Lex Luthor", content: <<-ARTICLE
Lex Luthor is a fictional character, a supervillain who appears in comic books published by DC Comics. He is the archenemy of Superman, and is also a major adversary of Batman and other superheroes in the DC Universe. Created by Jerry Siegel and Joe Shuster, he first appeared in Action Comics #23 (April 1940). Luthor is described as "a power-mad, evil scientist" of high intelligence and incredible technological prowess. (from Wikipedia)
ARTICLE

robin = Article.create! name: "Robin", content: <<-ARTICLE
Robin is the name of several fictional characters appearing in comic books published by DC Comics, originally created by Bob Kane, Bill Finger and Jerry Robinson, as a junior counterpart to DC Comics superhero Batman. The team of Batman and Robin is commonly referred to as the Dynamic Duo or the Caped Crusaders. (from Wikipedia)
ARTICLE
```

Create the tag model with name attribute.

```
rails g model tag name
```

Create the tagging model.

```
rails g model tagging tag:belongs_to article:belongs_to
```

Add indexes to the generated migrations.

```ruby
class CreateTaggings < ActiveRecord::Migration[5.0]
  def change
    create_table :taggings do |t|
      t.belongs_to :tag, foreign_key: true
      t.belongs_to :article, foreign_key: true

      t.timestamps
    end
    add_index :taggings, :tag_id
    add_index :taggings, :article_id
  end
end
```

```
rails db:migrate
```

You will get the error:

```
StandardError: An error has occurred, this and all later migrations canceled:

Index name 'index_taggings_on_tag_id' on table 'taggings' already exists
```

Remove:

```ruby
add_index :taggings, :tag_id
add_index :taggings, :article_id
```

Migrate the database.

```
rails db:migrate
```

Setup the associations in the models. In tag model:

```ruby
class Tag < ApplicationRecord
  has_many :taggings
  has_many :articles, through: :taggings
end
```

In article model:

```ruby
class Article < ApplicationRecord
  has_many :taggings
  has_many :tags, through: :taggings
  
  def self.tagged_with(name)
    Tag.find_by!(name: name).articles
  end
  
  def self.tag_counts
    Tag.select('tags.*, count(taggings.tag_id) as count').joins(:taggings).group('taggings.tag_id')
  end
  
  def tag_list
    tags.map(&:name).join(', ')
  end
  
  def tag_list=(names)
    self.tags = names.split(',').map do |n|
      Tag.where(name: n.strip).first_or_create!
    end
  end
end
```

Create the articles controller with index, new, show and edit actions.

```
rails g controller articles index new show edit
```

The articles controller is straightforward.

```ruby
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
    params.require(:article).permit(:name, :published_on, :content)
  end
end
```

In app/views/articles/index.html.erb, add the code to display the tags for an article:

```rhtml
<%= raw article.tags.map(&:name).map { |t| link_to t, tag_path(t) }.join(', ') %>
```

It will look like this:

```rhtml
<h1>Articles</h1>

<div id="tag_cloud">
  <% tag_cloud Article.tag_counts, %w[s m l] do |tag, css_class| %>
    <%= link_to tag.name, tag_path(tag.name), class: css_class %>
  <% end %>
</div>

<div id="articles">
  <% @articles.each do |article| %>
    <h2><%= link_to article.name, article %></h2>
    <%= simple_format article.content %>
    <p>
      Tags: <%= raw article.tags.map(&:name).map { |t| link_to t, tag_path(t) }.join(', ') %>
    </p>
    <p><%= link_to "Edit Article", edit_article_path(article) %></p>
  <% end %>
</div>

<p><%= link_to "New Article", new_article_path %></p>
```

Add css for tag cloud to articles.scss:

```css
#tag_cloud {
  width: 400px;
  line-height: 1.6em;
  .s { font-size: 0.8em; }
  .m { font-size: 1.2em; }
  .l { font-size: 1.8em; }
}
```

For layout.scss, refer the git repository for the source. Here is the implementation for the `tag_cloud`.

```ruby
module ApplicationHelper
  def tag_cloud(tags, classes)
    max = tags.sort_by(&:count).last
    tags.each do |tag|
      index = tag.count.to_f / max.count * (classes.size - 1)
      yield(tag, classes[index.round])
    end
  end
end
```

Populate sample data using seeds.rb:

```
rails db:seed
```

Define the resource in routes.rb.

```ruby
Rails.application.routes.draw do
  resources :articles
  
  root 'articles#index'
end
```

Start the rails server.

```
rails s
```

Go to `localhost:3000`. Edit an article and add some tags. It will fail with error:

```
Unpermitted parameter: tag_list
```

Add `tag_list` to the `article_params` method:

```ruby
def article_params
  params.require(:article).permit(:name, :published_on, :content, :tag_list)
end
```

Now the tag will get saved. If you go the articles index page, you will get the error:

```
Showing /Users/bparanj/projects/tug/app/views/articles/index.html.erb where line #5 raised:

undefined method `tag_path' for #<#<Class:0x007ff0a30e0e20>:0x007ff09d7d4a70>
Did you mean?  tag_option
```

Add:

```ruby
get 'tags/:tag', to: 'articles#index', as: :tag
```

to routes.rb. Now you will be able to see the tags for all the articles and the tag cloud.

Performance Tip by Oren Dobzinski: There's no need to sort the array only to pick the largest element. In application helper for the `tag_cloud` method: 

```ruby
max = tags.max_by(&:count)
```

## Summary

In this article, you learned how to implement tagging functionality for just one model in a Rails 5 app.

http://railscasts.com/episodes/382-tagging?view=comments


