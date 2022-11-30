schema "0001" do
  entity "Article" do
    string :title, optional: false

    datetime :created_at
    datetime :updated_at

    has_many :comments, inverse: "Comment.article", deletionRule: "Cascade", ordered: true
  end

  entity "Comment" do
    string :text, optional: false

    datetime :created_at
    datetime :updated_at

    belongs_to :article, inverse: "Article.comments"
  end
end