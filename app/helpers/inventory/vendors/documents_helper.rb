module Inventory::Vendors::DocumentsHelper
  def asset_thumb(asset)
    case true
      when asset.content_type.include?("pdf")
        image_thumb("photos/pdf-page.png")
      when asset.content_type.include?("text")
        image_thumb("photos/text.png")
      when asset.content_type.include?("ms-excel")
        image_thumb("photos/xls.png")
      when asset.content_type.include?("doc")
        image_thumb("photos/doc.ico")
      when ['jpeg', 'tif', 'png', 'gif'].any? { |s| asset.content_type.include?(s) }
        image_thumb(asset.asset_path_url, 'pic')
      when asset.content_type.include?("video/mp4")
      	video_thumb(asset.asset_path_url)
      else
        image_thumb("photos/text.png")
    end
  end

  def video_thumb(url)
  	video_tag url, size: "350x160", style: "height: 100px", controls: true
  end

  def image_thumb(url, css_class= 'icon')
  	image_tag url, class: "img-responsive img-#{css_class}"
  end
end