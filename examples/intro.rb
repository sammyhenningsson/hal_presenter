require 'hal_presenter'

class Intro
  Comment = Struct.new(:id, :comment) do
    def href
      "/posts/5/comment/#{id}"
    end
  end

  Author = Struct.new(:id)

  Post = Struct.new(:id, :author, :text, :recent_comments)

  class CommentSerializer
    extend HALPresenter
    model Comment

    attribute :comment

    link :self do
      resource.href
    end

    collection of: 'comments' do
      attribute :count

      link :self, "/posts/5/recent_comments"
    end
  end

  class PostSerializer
    extend HALPresenter
    model Post

    attribute :text
    attribute :characters do
      resource.text.size
    end

    link :self do
      "/posts/#{resource.id}"
    end

    link :author do
      "/users/#{resource.author.id}"
    end

    link :edit do
      "/posts/#{resource.id}/edit" if resource.author.id == options[:current_user]
    end

    link :delete do
      "/posts/#{resource.id}" if resource.author.id == options[:current_user]
    end

    embed :recent_comments
  end

  def self.call
    author = Author.new(8)
    comments = [
      Comment.new(1, "lorem ipsum"),
      Comment.new(2, "dolor sit"),
    ]
    post = Post.new(5, author, "some very important stuff", comments)

    puts HALPresenter.to_hal(post, current_user: author.id)
  end
end

Intro.call

# {
#   "text": "some very important stuff",
#   "characters": 25,
#   "_links": {
#     "self": {
#       "href": "/posts/5"
#     },
#     "author": {
#       "href": "/users/8"
#     },
#     "edit": {
#       "href": "/posts/5/edit"
#     },
#     "delete": {
#       "href": "/posts/5"
#     }
#   },
#   "_embedded": {
#     "recent_comments": {
#       "count": 2,
#       "_links": {
#         "self": {
#           "href": "/posts/5/recent_comments"
#         }
#       },
#       "_embedded": {
#         "comments": [
#           {
#             "comment": "lorem ipsum",
#             "_links": {
#               "self": {
#                 "href": "/posts/5/comment/1"
#               }
#             }
#           },
#           {
#             "comment": "dolor sit",
#             "_links": {
#               "self": {
#                 "href": "/posts/5/comment/2"
#               }
#             }
#           }
#         ]
#       }
#     }
#   }
# }
