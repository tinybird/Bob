require 'digest/md5'

module MailerHelper
  
  def avatar_url(author)
    # We assume the author is on the form Name <email>.
    matches = author.match(/.*<(.*)>/)
    if matches.length > 1
      digest = Digest::MD5.hexdigest(matches[1])
    else
      # We fall back to gravatar's icon (any invalid md5 will give us that).
      digest = "xxx"
    end
    
    return "http://www.gravatar.com/avatar/#{digest}.png?s=36"
  end
  
  def revision_url(project, revision)
    user = project.url.match(/git@github.com:(.*)\//)[1]
    return "https://github.com/#{user}/#{project.name}/commit/#{revision.sha}"
  end

 def is_ignored_file?(project, path)
    path = path.downcase
    ignored = [".png", ".jpg", ".tiff", ".svg", ".ico", ".icns", ".pxm",
               ".wav", ".m4a", ".mp3", ".aif", ".caf", ".band",
               ".nib", ".xib", ".xcodeproj", ".xcdatamodel",
               ".sqlite", ".graffle", ".psd", ".xcf" ]
    ignored = ignored.concat(project.ignored_file_extensions)
    ignored.each do |suffix|
      Pathname.new(path).each_filename do |component|
        if component.end_with?(suffix)
				  return true
			  end
		  end
		end
    return false
	end

  def is_binary?(str)
	  # Use some heuristics: if more than X% of the characters are non-ascii, count
	  # the string as binary (but hopefully not unicode).
	  count = 0.0
	  non_ascii_count = 0.0
	  str.each_byte do |b|
		  if b > 128
			  non_ascii_count = non_ascii_count + 1
			end

			count = count + 1;
			if count > 200
				break
			end
		end
		return non_ascii_count / count > 0.6
  end
  
end
