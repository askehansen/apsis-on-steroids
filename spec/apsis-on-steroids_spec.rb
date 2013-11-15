require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ApsisOnSteroids" do
  let(:aos) do
    ApsisOnSteroids.new(
      :api_key => File.read("#{File.dirname(__FILE__)}/api_key.txt").strip,
      :debug => false
    )
  end

  it "can connect" do
    aos
  end
  
  it "should create and delete a mailing list" do
    name = "create-mlist-#{Time.now.to_f.to_s}"
    
    aos.create_mailing_list(
      :Name => name,
      :FromName => "Kasper Johansen",
      :FromEmail => "kj@naoshi-dev.com",
      :CharacterSet => "utf-8"
    )
    
    mlist = aos.mailing_list_by_name(name)
    
    sleep 1
    mlist.delete
  end

  it "can get a mailing list" do
    mlist = aos.mailing_list_by_name("kj")
  end

  context do
    let(:mlist) do
      mlist = aos.mailing_list_by_name("kj")
      mlist.remove_all_subscribers
      mlist
    end
    
    let(:sub) do
      email = "kaspernj#{Time.now.to_f}@naoshi-dev.com"
      mlist.create_subscribers([{
        :Email => email,
        :Name => "Kasper Johansen"
      }])
      aos.subscriber_by_email(email)
    end
  
    it "can create subscribers" do
      sub
    end
    
    it "can get subscribers and their details" do
      details = sub.details
      details.is_a?(Hash).should eql(true)
      details.key?(:pending).should eql(false)
    end

    it "can update subscribers" do
      new_email = "kaspernj#{Time.now.to_f}-updated@naoshi-dev.com"
      sub.update(:Email => new_email)
      sleep 1
      sub.details[:Email].should eql(new_email)
      sub.details[:Name].should eql("Kasper Johansen")
    end

    it "should not overwrite data when updating" do
      phone = Time.now.to_i.to_s
      sub.update(:PhoneNumber => phone)
      sub.details[:PhoneNumber].should eql(phone)

      new_email = "kaspernj#{Time.now.to_f}-updated@naoshi-dev.com"
      sub.update(:Email => new_email)
      sub.details[:Email].should eql(new_email)

      sub.details[:PhoneNumber].should eql(phone)
    end

    it "can lookup the subscriber on the list" do
      mlist.subscriber_by_email(sub.data(:email)).should_not eq nil
    end
    
    it "can get lists of subscribers from lists" do
      original_sub = sub
      
      count = 0
      mlist.subscribers do |sub_i|
        count += 1
        #puts "Subscriber: #{sub_i}"
      end
      
      raise "Expected more than one." if count < 1
    end

    it "can remove subscribers from lists" do
      mlist.remove_subscriber(sub)
    end

    it "can validate if a subscriber is active or not" do
      sub.active?.should eql(true)
    end
    
    it "can subscribe, remove and then re-subscribe" do
      sub.active?.should eql(true)
      
      mlist.remove_subscriber(sub)
      mlist.add_subscriber(sub)
      
      sub.active?.should eql(true)
      mlist.member?(sub).should eql(true)
    end
    
    it "should be able to opt out a subscriber" do
      mlist.opt_out_subscriber(sub)
      mlist.opt_out?(sub).should eql(true)
      mlist.opt_out_remove_subscriber(sub)
      mlist.opt_out?(sub).should eql(false)
    end
    
    it "trying to an email that does not exist should raise the correct error" do
      expect{
        aos.subscriber_by_email("asd@asd.com")
      }.to raise_error(ApsisOnSteroids::Errors::SubscriberNotFound)
    end

    it "can create, finda and remove subscriber with +" do
      email = "kaspernj#{Time.now.to_f}+test@naoshi-dev.com"
      mlist.create_subscribers([{
        :Email => email,
        :Name => "Kasper Johansen"
      }])
      sub = aos.subscriber_by_email(email)
      mlist.remove_subscriber(sub)
    end
  end
end
