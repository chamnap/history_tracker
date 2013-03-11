require 'spec_helper'

describe 'Tracking changes when destroy' do
  context "when enabled" do
    it 'should record changes when destroy' do
      book = Book.create!(name: 'MongoDB 102', read_count: 102)
      expect {
        book.destroy
      }.to change { Book.history_class.count }.by(1)
    end

    it 'should retrieve changes history' do
      book = Book.create!(name: 'MongoDB 102', read_count: 102)
      book.destroy

      tracked = book.history_tracks.last
      tracked.should be_present
      # tracked.version.should  == 1
      tracked.original.should include({"id"=>book.id, "name"=>"MongoDB 102", "read_count"=>102})
      tracked.modified.should == {}
      tracked.changeset.should == {}
      tracked.action.should   == "destroy"
      tracked.scope.should    == "book"
    end

    it 'should track changes with :class_name' do
      book = BookClassName.create!(name: 'MongoDB 101', read_count: 101)

      expect {
        book.destroy
      }.to change { BookHistory.count }.by(1)
    end

    it 'should track changes with :only options' do
      book = BookOnly.create!(name: 'MongoDB 101', read_count: 101)
      book.destroy

      book.history_tracks.last.modified.should == {}
      book.history_tracks.last.original.should include({"id"=>book.id, "name"=>"MongoDB 101", "read_count"=>101})
    end

    it 'should track changes with :except options' do
      book = BookExcept.create!(name: 'MongoDB 101', read_count: 101)
      book.destroy

      book.history_tracks.last.original.should include({"id"=>book.id, "name"=>"MongoDB 101", "read_count"=>101})
      book.history_tracks.last.modified.should == {}
    end

    it 'should track change with on: [:destroy]' do
      book = BookOnDestroy.new(name: 'MongoDB 101', description: 'Open source document database', is_active: true, read_count: 5)

      expect { book.save }.to_not change { BookOnDestroy.history_class.count }.by(1)
      expect { book.update_attributes!(name: 'MongoDB 102') }.to_not change { BookOnDestroy.history_class.count }
      expect { book.destroy }.to change { BookOnDestroy.history_class.count }
    end
  end

  context "when disabled" do
    before(:each) do
      @book = Book.create!(name: 'MongoDB 101', read_count: 101)
    end

    after(:each) do
      Book.enable_tracking
    end
    
    it "should not track" do
      Book.disable_tracking

      expect { @book.destroy }.to change { Book.history_class.count }.by(0)
    end

    it "should not track #without_tracking without :destroy" do
      expect { @book.without_tracking { @book.destroy } }.to change { Book.history_class.count }.by(0)
    end

    it "should not track #without_tracking with :destroy" do
      expect { @book.without_tracking(:destroy) }.to change { Book.history_class.count }.by(0)
    end
  end
end