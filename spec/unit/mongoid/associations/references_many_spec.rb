require "spec_helper"

describe Mongoid::Associations::ReferencesMany do
  
  context "normal association" do

    let(:block) do
      Proc.new do
        def extension
          "Testing"
        end
      end
    end

    let(:options) do
      Mongoid::Associations::Options.new(
        :name => :posts,
        :foreign_key => "person_id",
        :extend => block
      )
    end

    describe "#<<" do

      before do
        @child = Post.instantiate(:id => "4c52c439931a90ab29000001")
        @second = Post.instantiate(:id => "4c52c439931a90ab29000002")
        @children = [@child, @second]
      end

      context "when parent document has been saved" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => false, :class => Person)
          Post.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "saves and appends the child document" do
          @child.expects(:write_attribute).with('person_id', @parent.id)
          @child.expects(:save).returns(true)
          @association << @child
          @association.size.should == 1
        end

      end

      context "when parent document has not been saved" do

        context "when appending a non mongoid object" do

          before do
            @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => true, :class => Person)
            Post.expects(:all).returns([])
            @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
          end

          it "appends the child document" do
            @child.expects(:write_attribute).with('person_id', @parent.id)
            @association << @child
            @association.size.should == 1
          end
        end

        context "when appending a mongoid document" do

          before do
            @criteria = mock
            @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => true, :class => Person)
            Post.expects(:all).returns(@criteria)
            @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
          end

          it "appends the child document" do
            @criteria.expects(:entries).returns([])
            @child.expects(:write_attribute).with('person_id', @parent.id)
            @association << @child
            @association.size.should == 1
          end
        end

      end

      context "with multiple objects" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => true, :class => Person)
          Post.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "appends the child documents" do
          @child.expects(:write_attribute).with('person_id', @parent.id)
          @second.expects(:write_attribute).with('person_id', @parent.id)
          @association << [@child, @second]
          @association.size.should == 2
        end

      end

    end

    describe "#build" do

      before do
        @criteria = mock
        @criteria.expects(:entries).returns([])
        @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person, :new_record? => true)
        Post.expects(:all).returns(@criteria)
        @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
      end

      it "adds a new object to the association" do
        @association.build(:title => "Sassy")
        @association.size.should == 1
      end

      it "sets the parent object id on the child" do
        @association.build(:title => "Sassy")
        @association.first.person_id.should == BSON::ObjectID(@parent.id)
      end

      it "returns the new object" do
        @association.build(:title => "Sassy").title.should == "Sassy"
      end

      it "sets the parent object reference on the child" do
        @association.build(:title => "Sassy")
        @association.first.person.should == @parent
      end

      context "when passing nil" do

        it "builds an object with empty attributes" do
          @association.build(nil)
          @association.first.person.should == @parent
        end
      end
    
      it "sets the foreign key when it is protected from mass assignment" do
        Account.expects(:all).returns(@criteria)
        options = Mongoid::Associations::Options.new(
          :name => :accounts,
          :foreign_key => "person_id"
        )
        @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        @association.build(:nickname => "Checking")
        @association.first.person_id.should == BSON::ObjectID(@parent.id)
      end
    end

    describe '#build (2)' do
      it 'should build associated object correctly when there are two associations to the same object' do
        user = User.create!
        description = user.descriptions.build :details => 'Likes peanut butter...'
        description.user.should_not == nil
      end
    end

    describe "#delete_all" do

      before do
        @criteria = mock
        @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person, :new_record? => true)
        Post.expects(:all).twice.returns(@criteria)
        @parent.expects(:reset).with("posts").yields
        @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
      end

      it "deletes all of the associated object" do
        Post.expects(:delete_all).with(:conditions => { :person_id => "4c52c439931a90ab29000005" }).returns(3)
        @association.delete_all.should == 3
      end
    end

    describe "#destroy_all" do

      before do
        @criteria = mock
        @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person, :new_record? => true)
        Post.expects(:all).twice.returns(@criteria)
        @parent.expects(:reset).with("posts").yields
        @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
      end

      it "destroys all of the associated objects" do
        Post.expects(:destroy_all).with(:conditions => { :person_id => "4c52c439931a90ab29000005" }).returns(3)
        @association.destroy_all.should == 3
      end
    end

    describe "#concat" do

      before do
        @child = Post.instantiate(:id => "4c52c439931a90ab29000001")
        @second = Post.instantiate(:id => "4c52c439931a90ab29000002")
      end

      context "when parent document has been saved" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => false, :class => Person)
          Post.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "saves and appends the child document" do
          @child.expects(:write_attribute).with('person_id', @parent.id)
          @child.expects(:save).returns(true)
          @association.concat(@child)
          @association.size.should == 1
        end

      end

      context "when parent document has not been saved" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => true, :class => Person)
          Post.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "appends the child document" do
          @child.expects(:write_attribute).with('person_id', @parent.id)
          @association.concat(@child)
          @association.size.should == 1
        end

      end

      context "with multiple objects" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => true, :class => Person)
          Post.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "appends the child documents" do
          @child.expects(:write_attribute).with('person_id', @parent.id)
          @second.expects(:write_attribute).with('person_id', @parent.id)
          @association.concat([@child, @second])
          @association.size.should == 2
        end

      end

    end

    describe "#create" do

      before do
        @post = Post.new
        @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person, :new_record? => true)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        Post.expects(:instantiate).returns(@post)
      end

      it "can be called with no arguments" do
        @post.expects(:save).returns(true)
        expect { @association.create }.to_not raise_error
      end

      it "builds and saves the new object" do
        @post.expects(:save).returns(true)
        @association.create(:title => "Sassy")
      end

      it "returns the new object" do
        @post.expects(:save).returns(true)
        @association.create(:title => "Sassy").should == @post
      end

    end

    describe "#create!" do

      before do
        @post = Post.new
        @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person, :new_record? => true)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        Post.expects(:instantiate).returns(@post)
      end

      it "can be called with no arguments" do
        @post.expects(:save!).returns(true)
        expect { @association.create! }.to_not raise_error
      end

      it "builds and saves the new object" do
        @post.expects(:save!).returns(true)
        @association.create!(:title => "Sassy")
      end

      it "returns the new object" do
        @post.expects(:save!).returns(true)
        @association.create!(:title => "Sassy").should == @post
      end

    end

    describe "#find" do

      before do
        @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
      end

      context "when finding by id" do

        before do
          @post = stub
        end

        it "returns the document in the array with that id" do
          @association.expects(:id_criteria).with("4c52c439931a90ab29000005").returns(@post)
          post = @association.find("4c52c439931a90ab29000005")
          post.should == @post
        end
      end

      context "when finding all with conditions" do

        before do
          @post = stub
        end

        it "passes the conditions to the association class" do
          Post.expects(:find).with(:all, :conditions => { :title => "Testing", :person_id => @parent.id }).returns([@post])
          posts = @association.find(:all, :conditions => { :title => "Testing" })
          posts.should == [@post]
        end

      end

      context "when finding first with conditions" do

        before do
          @post = stub
        end

        it "passes the conditions to the association class" do
          Post.expects(:find).with(:first, :conditions => { :title => "Testing", :person_id => @parent.id }).returns(@post)
          post = @association.find(:first, :conditions => { :title => "Testing" })
          post.should == @post
        end

      end

      context "when finding last with conditions" do

        before do
          @post = stub
        end

        it "passes the conditions to the association class" do
          Post.expects(:find).with(:last, :conditions => { :title => "Testing", :person_id => @parent.id }).returns(@post)
          post = @association.find(:last, :conditions => { :title => "Testing" })
          post.should == @post
        end

      end

    end

    describe ".initialize" do

      before do
        @document = Person.new
        @criteria = stub
        @first = stub(:person_id => @document.id)
        @second = stub(:person_id => @document.id)
        @related = [@first, @second]
        Post.expects(:all).with(:conditions => { :person_id => @document.id }).returns(@related)
      end

      context "when related id has been set" do

        it "finds the object by id" do
          association = Mongoid::Associations::ReferencesMany.new(@document, options)
          association.should == @related
        end

      end

      context "when the options have an extension" do

        it "adds the extension module" do
          association = Mongoid::Associations::ReferencesMany.new(@document, options)
          association.extension.should == "Testing"
        end

      end

    end

    describe ".instantiate" do

      context "when related id has been set" do

        before do
          @document = Person.new
        end

        it "delegates to new" do
          Mongoid::Associations::ReferencesMany.expects(:new).with(@document, options, nil)
          association = Mongoid::Associations::ReferencesMany.instantiate(@document, options)
        end

      end

    end

    describe ".macro" do

      it "returns :references_many" do
        Mongoid::Associations::ReferencesMany.macro.should == :references_many
      end

    end

    describe "#nested_build" do

      before do
        @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => false, :class => Person)

        @first = Post.new(:id => "4c52c439931a90ab29000000")
        @second = Post.new(:id => "4c52c439931a90ab29000001")
        @related = [@first, @second]
        Post.expects(:all).returns(@related)
        @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
      end

      it "should update existing documents" do
        @association.expects(:find).with("4c52c439931a90ab29000000").returns(@first)
        @association.nested_build({ "0" => { "id" => "4c52c439931a90ab29000000", "title" => "Yet Another" } })
        @association.size.should == 2
        @association[0].title.should == "Yet Another"
      end

      it "should create new documents" do
        @association.expects(:find).with(nil).raises(Mongoid::Errors::DocumentNotFound.new(Post, nil))
        @association.nested_build({ "2" => { "title" => "Yet Another" } })
        @association.size.should == 3
        @association[2].title.should == "Yet Another"
      end

    end

    describe "#push" do

      before do
        @child = Post.instantiate(:id => "4c52c439931a90ab29000001")
        @second = Post.instantiate(:id => "4c52c439931a90ab29000002")
      end

      context "when parent document has been saved" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => false, :class => Person)
          Post.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "saves and appends the child document" do
          @child.expects(:write_attribute).with('person_id', @parent.id)
          @child.expects(:save).returns(true)
          @association.push(@child)
          @association.size.should == 1
        end

      end

      context "when parent document has not been saved" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => true, :class => Person)
          Post.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "appends the child document" do
          @child.expects(:write_attribute).with('person_id', @parent.id)
          @association.push(@child)
          @association.size.should == 1
        end

      end

      context "with multiple objects" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => true, :class => Person)
          Post.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "appends the child documents" do
          @child.expects(:write_attribute).with('person_id', @parent.id)
          @second.expects(:write_attribute).with('person_id', @parent.id)
          @association.push(@child, @second)
          @association.size.should == 2
        end

      end

    end

    describe ".update" do

      before do
        @first = Post.new
        @second = Post.new
        @related = [@first, @second]
        @parent = Person.new
      end

      it "sets the related object id on the parent" do
        Mongoid::Associations::ReferencesMany.update(@related, @parent, options)
        @first.person_id.should == @parent.id
        @second.person_id.should == @parent.id
      end

      it "returns the related objects" do
        @proxy = Mongoid::Associations::ReferencesMany.update(@related, @parent, options)
        @proxy.target.should == @related
      end
    end
  end
  
  context "polymorphic association" do

    let(:options) do
      Mongoid::Associations::Options.new(
        :name => :mansions,
        :as => :owner
      )
    end

    describe "#<<" do

      before do
        @child = Mansion.instantiate(:id => "4c52c439931a90ab29000001")
        @second = Mansion.instantiate(:id => "4c52c439931a90ab29000002")
        @children = [@child, @second]
      end

      context "when parent document has been saved" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => false, :class => Person)
          Mansion.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "saves and appends the child document" do
          @child.expects(:write_attribute).with('owner_id.type', "Person")
          @child.expects(:write_attribute).with('owner_id.id', @parent.id)

          @child.expects(:save).returns(true)
          @association << @child
          @association.size.should == 1
        end

      end

      context "when parent document has not been saved" do

        context "when appending a non mongoid object" do

          before do
            @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => true, :class => Person)
            Mansion.expects(:all).returns([])
            @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
          end

          it "appends the child document" do
            @child.expects(:write_attribute).with('owner_id.type', "Person")
            @child.expects(:write_attribute).with('owner_id.id', @parent.id)

            @association << @child
            @association.size.should == 1
          end
        end

        context "when appending a mongoid document" do

          before do
            @criteria = mock
            @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => true, :class => Person)
            Mansion.expects(:all).returns(@criteria)
            @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
          end

          it "appends the child document" do
            @criteria.expects(:entries).returns([])
            @child.expects(:write_attribute).with('owner_id.type', "Person")
            @child.expects(:write_attribute).with('owner_id.id', @parent.id)
            
            @association << @child
            @association.size.should == 1
          end
        end

      end

      context "with multiple objects" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => true, :class => Person)
          Mansion.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "appends the child documents" do
          @child.expects(:write_attribute).with('owner_id.type', "Person")
          @child.expects(:write_attribute).with('owner_id.id', @parent.id)
          @second.expects(:write_attribute).with('owner_id.type', "Person")
          @second.expects(:write_attribute).with('owner_id.id', @parent.id)
          
          @association << [@child, @second]
          @association.size.should == 2
        end

      end

    end

    describe "#build" do

      before do
        @criteria = mock
        @criteria.expects(:entries).returns([])
        @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person, :new_record? => true)
        Mansion.expects(:all).returns(@criteria)
        @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
      end

      it "adds a new object to the association" do
        @association.build(:name => "Sassy")
        @association.size.should == 1
      end

      it "sets the parent object id on the child" do
        @association.build(:name => "Sassy")
        @association.first.owner_id.id.should == BSON::ObjectID(@parent.id)
        @association.first.owner_id.klass.should == "Person"
      end

      it "sets the parent object reference on the child" do
        @association.build(:name => "Sassy")
        @association.first.owner.should == @parent
      end

      context "when passing nil" do

        it "builds an object with empty attributes" do
          @association.build(nil)
          @association.first.owner.should == @parent
        end
      end
    end

    describe "#delete_all" do

      before do
        @criteria = mock
        @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person, :new_record? => true)
        Mansion.expects(:all).twice.returns(@criteria)
        @parent.expects(:reset).with("mansions").yields
        @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
      end

      it "deletes all of the associated object" do
        Mansion.expects(:delete_all).with(:conditions => { "owner_id.id" => "4c52c439931a90ab29000005", "owner_id.type" => "Person" }).returns(3)
        @association.delete_all.should == 3
      end
    end

    describe "#destroy_all" do

      before do
        @criteria = mock
        @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person, :new_record? => true)
        Mansion.expects(:all).twice.returns(@criteria)
        @parent.expects(:reset).with("mansions").yields
        @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
      end

      it "destroys all of the associated objects" do
        Mansion.expects(:destroy_all).with(:conditions => { "owner_id.id" => "4c52c439931a90ab29000005", "owner_id.type" => "Person" }).returns(3)
        @association.destroy_all.should == 3
      end
    end

    describe "#concat" do

      before do
        @child = Mansion.instantiate(:id => "4c52c439931a90ab29000001")
        @second = Mansion.instantiate(:id => "4c52c439931a90ab29000002")
      end

      context "when parent document has been saved" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => false, :class => Person)
          Mansion.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "saves and appends the child document" do
          @child.expects(:write_attribute).with('owner_id.type', "Person")
          @child.expects(:write_attribute).with('owner_id.id', @parent.id)

          @child.expects(:save).returns(true)
          @association.concat(@child)
          @association.size.should == 1
        end

      end

      context "when parent document has not been saved" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => true, :class => Person)
          Mansion.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "appends the child document" do
          @child.expects(:write_attribute).with('owner_id.type', "Person")
          @child.expects(:write_attribute).with('owner_id.id', @parent.id)

          @association.concat(@child)
          @association.size.should == 1
        end

      end

      context "with multiple objects" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => true, :class => Person)
          Mansion.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "appends the child documents" do
          @child.expects(:write_attribute).with('owner_id.type', "Person")
          @child.expects(:write_attribute).with('owner_id.id', @parent.id)
          @second.expects(:write_attribute).with('owner_id.type', "Person")
          @second.expects(:write_attribute).with('owner_id.id', @parent.id)
          @association.concat([@child, @second])
          @association.size.should == 2
        end

      end

    end

    describe "#create" do

      before do
        @mansion = Mansion.new
        @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person, :new_record? => true)
        Mansion.expects(:all).returns([])
        @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        Mansion.expects(:instantiate).returns(@mansion)
      end

      it "can be called with no arguments" do
        @mansion.expects(:save).returns(true)
        expect { @association.create }.to_not raise_error
      end

      it "builds and saves the new object" do
        @mansion.expects(:save).returns(true)
        @association.create(:name => "Sassy")
      end

      it "returns the new object" do
        @mansion.expects(:save).returns(true)
        @association.create(:name => "Sassy").should == @mansion
      end

    end

    describe "#create!" do

      before do
        @mansion = Mansion.new
        @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person, :new_record? => true)
        Mansion.expects(:all).returns([])
        @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        Mansion.expects(:instantiate).returns(@mansion)
      end

      it "can be called with no arguments" do
        @mansion.expects(:save!).returns(true)
        expect { @association.create! }.to_not raise_error
      end

      it "builds and saves the new object" do
        @mansion.expects(:save!).returns(true)
        @association.create!(:name => "Sassy")
      end

      it "returns the new object" do
        @mansion.expects(:save!).returns(true)
        @association.create!(:name => "Sassy").should == @mansion
      end

    end

    describe "#find" do

      before do
        @parent = stub(:id => "4c52c439931a90ab29000005", :class => Person)
        Mansion.expects(:all).returns([])
        @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
      end

      context "when finding by id" do

        before do
          @mansion = stub
        end

        # TODO - This
        it "returns the document in the array with that id" do
          @association.expects(:id_criteria).with("4c52c439931a90ab29000005").returns(@post)
          post = @association.find("4c52c439931a90ab29000005")
          post.should == @post
        end
      end

      context "when finding all with conditions" do

        before do
          @mansion = stub
        end

        it "passes the conditions to the association class" do
          Mansion.expects(:find).with(:all, :conditions => { :name => "Testing", "owner_id.id" => @parent.id, "owner_id.type" => "Person" }).returns([@mansion])
          mansions = @association.find(:all, :conditions => { :name => "Testing" })
          mansions.should == [@mansion]
        end

      end

      context "when finding first with conditions" do

        before do
          @mansion = stub
        end

        it "passes the conditions to the association class" do
          Mansion.expects(:find).with(:first, :conditions => { :name => "Testing", "owner_id.id" => @parent.id, "owner_id.type" => "Person" }).returns(@mansion)
          mansion = @association.find(:first, :conditions => { :name => "Testing" })
          mansion.should == @mansion
        end

      end

      context "when finding last with conditions" do

        before do
          @mansion = stub
        end

        it "passes the conditions to the association class" do
          Mansion.expects(:find).with(:last, :conditions => { :name => "Testing", "owner_id.id" => @parent.id, "owner_id.type" => "Person" }).returns(@mansion)
          mansion = @association.find(:last, :conditions => { :name => "Testing" })
          mansion.should == @mansion
        end

      end

    end

    describe ".initialize" do

      before do
        @document = Person.new
        @criteria = stub
        @first = stub("owner_id.id" => @document.id, "owner_id.type" => @document.class.name)
        @second = stub("owner_id.id" => @document.id, "owner_id.type" => @document.class.name)
        @related = [@first, @second]
        Mansion.expects(:all).with(:conditions => { "owner_id.id" => @document.id, "owner_id.type" => @document.class.name }).returns(@related)
      end

      context "when related id has been set" do

        it "finds the object by id" do
          association = Mongoid::Associations::ReferencesMany.new(@document, options)
          association.should == @related
        end

      end

    end

    describe "#nested_build" do

      before do
        @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => false, :class => Person)

        @first = Mansion.new(:id => "4c52c439931a90ab29000000")
        @second = Mansion.new(:id => "4c52c439931a90ab29000001")
        @related = [@first, @second]
        Mansion.expects(:all).returns(@related)
        @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
      end

      it "should update existing documents" do
        @association.expects(:find).with("4c52c439931a90ab29000000").returns(@first)
        @association.nested_build({ "0" => { "id" => "4c52c439931a90ab29000000", "title" => "Yet Another" } })
        @association.size.should == 2
        @association[0].title.should == "Yet Another"
      end

      it "should create new documents" do
        @association.expects(:find).with(nil).raises(Mongoid::Errors::DocumentNotFound.new(Post, nil))
        @association.nested_build({ "2" => { "title" => "Yet Another" } })
        @association.size.should == 3
        @association[2].title.should == "Yet Another"
      end

    end

    describe "#push" do

      before do
        @child = Post.instantiate(:id => "4c52c439931a90ab29000001")
        @second = Post.instantiate(:id => "4c52c439931a90ab29000002")
      end

      context "when parent document has been saved" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => false, :class => Person)
          Mansion.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "saves and appends the child document" do
          @child.expects(:write_attribute).with('owner_id.type', "Person")
          @child.expects(:write_attribute).with('owner_id.id', @parent.id)

          @child.expects(:save).returns(true)
          @association.push(@child)
          @association.size.should == 1
        end

      end

      context "when parent document has not been saved" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => true, :class => Person)
          Mansion.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "appends the child document" do
          @child.expects(:write_attribute).with('owner_id.type', "Person")
          @child.expects(:write_attribute).with('owner_id.id', @parent.id)

          @association.push(@child)
          @association.size.should == 1
        end

      end

      context "with multiple objects" do

        before do
          @parent = stub(:id => "4c52c439931a90ab29000001", :new_record? => true, :class => Person)
          Mansion.expects(:all).returns([])
          @association = Mongoid::Associations::ReferencesMany.new(@parent, options)
        end

        it "appends the child documents" do
          @child.expects(:write_attribute).with('owner_id.type', "Person")
          @child.expects(:write_attribute).with('owner_id.id', @parent.id)
          @second.expects(:write_attribute).with('owner_id.type', "Person")
          @second.expects(:write_attribute).with('owner_id.id', @parent.id)
          @association.push(@child, @second)
          @association.size.should == 2
        end

      end

    end

    describe ".update" do

      before do
        @first = Post.new
        @second = Post.new
        @related = [@first, @second]
        @parent = Person.new
      end

      it "sets the related object id on the parent" do
        Mongoid::Associations::ReferencesMany.update(@related, @parent, options)
        @first.person_id.should == @parent.id
        @second.person_id.should == @parent.id
      end

      it "returns the related objects" do
        @proxy = Mongoid::Associations::ReferencesMany.update(@related, @parent, options)
        @proxy.target.should == @related
      end
    end

  end
end
