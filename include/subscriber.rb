class ApsisOnSteroids::Subscriber < ApsisOnSteroids::SubBase
  # Fetches the details from the server and returns them.
  def details
    res = aos.req_json("v1/subscribers/id/#{data(:id)}")
    
    ret = {}
    res["Result"].each do |key, val|
      ret[key.to_sym] = val
    end
    
    return ret
  end
  
  # Returns true if the subscriber is active.
  def active?
    details = self.details
    
    if details[:pending]
      return false
    end
    
    return true
  end
  
  # Update one or more details on the subscriber.
  def update(data)
    res = aos.req_json("v1/subscribers/queue", :post, :json => [
      {
        :Id => data(:id)
      }.merge(data)
    ])
    
    url = URI.parse(res["Result"]["PollURL"])
    data = nil
    
    loop do
      res = aos.req_json(url.path)
      
      if res["State"] == "2"
        url_data = URI.parse(res["DataUrl"])
        data = aos.req_json(url_data.path)
        break
      end
    end
    
    raise data["FailedUpdatedSubscribers"].to_s if data["FailedUpdatedSubscribers"] && data["FailedUpdatedSubscribers"].any?
    return nil
  end
end