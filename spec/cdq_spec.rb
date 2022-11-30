module Bacon
  class Context
    include CDQ
  end
end

describe "cdq" do
  before do
    cdq.reset!
    cdq.setup
  end  

  after do
    cdq.reset!
  end

  it "runs on main thread successfully" do
    Article.count.should == 0

    article = Article.create(title: "ARTICLE1")
    article.comments.create(
      text: "COMMENT1"
    )

    cdq.save

    article.title.should == "ARTICLE1"

    article = Article.where(:title).eq("ARTICLE1").first
    article.title.should == "ARTICLE1"    
    article.comments.count.should == 1
  end

  it "runs on a concurrent thread and intermittently crashes in CDQManagedObject#relationshipByName" do
    @done = 0

    (1..10).each do |n|
      Dispatch::Queue.concurrent(:background).async do
  
        cdq.background(wait: true) do
          (1..100).each do |x|        
            article = Article.create(title: "TITLE-#{n}-#{x}")
            article.comments.create(
              text: "COMMENT-#{n}-#{x}"
            )
          end

          cdq.save(always_wait: true)
          @done += 1
          if @done == 10
            Dispatch::Queue.main.async { resume }
          end
        end
      end
    end

    Dispatch::Queue.main.async do      
      (1..1000).each do |x|

        article = Article.create(title: "TITLE-#{x}")
        article.comments.create(
          text: "COMMENT-#{x}"
        )
        cdq.save
        article.destroy
      end
      cdq.save
    end

    wait_max 15 do
      Article.all.count.should == 1000

      article = Article.where(:title).eq("TITLE-1-1").first
      article.title.should == "TITLE-1-1"
    end
  end
end