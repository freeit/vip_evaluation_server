module VipPack
  def packed?(data)
    data.start_with?("ZIP:")
  end

  def unpack(data)
    if packed?(data)
      Rails.logger.info "***** JobEvent#unpack: data is zipped."
      data = data.sub(/^ZIP:/,'')
      data = Base64.decode64(data)
      data = Zip::InputStream.open(StringIO.new(data)) do |io|
        io.get_next_entry
        io.read
      end
      Rails.logger.info "***** JobEvent#unpack: unzipped data = #{data}"
    else
      Rails.logger.info "***** JobEvent#unpack: data is not packed."
    end
    data
  end
end
