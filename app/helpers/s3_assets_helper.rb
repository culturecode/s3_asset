module S3AssetsHelper
  require 'base64'
  require 'openssl'
  require 'digest/sha1'
  
  def s3_url
    S3_URL
  end
  
  def s3_policy(dir)
    policy_document = {"expiration" => (Time.now + 1.hour).gmtime, "conditions" => [{"bucket" => ENV['S3_BUCKET']}, 
                                                                                    ["starts-with", "$key", dir + "/"],
                                                                                    ["starts-with", "$Content-Type", ""],
                                                                                    ["starts-with", "$Filename", ""],
                                                                                    ["starts-with", "$name", ""],
                                                                                    ["eq", '$success_action_status', "201"],
                                                                                    {"acl" => "public-read"}]}
    Base64.encode64(policy_document.to_json).gsub("\n","")
  end
  
  def s3_signature(dir)
    Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), ENV['S3_SECRET'], s3_policy(dir))).gsub("\n","")
  end
  
  def s3_hidden_fields(object_name, options = {})
    object_name = object_name.to_s
    
    hidden_field_tag("s3_url", s3_url) +
    hidden_field_tag("s3_dir", object_name.pluralize) +
    hidden_field_tag("AWSAccessKeyId", ENV['S3_KEY'], :class => "s3_field" ) +
    hidden_field_tag("acl", "public-read", :class => "s3_field" ) +
    hidden_field_tag("policy", s3_policy(object_name.pluralize), :class => "s3_field" ) +
    hidden_field_tag("signature", s3_signature(object_name.pluralize), :class => "s3_field" ) +
    hidden_field_tag("success_action_status", "201", :class => "s3_field") +
    hidden_field_tag("s3_uploaded_callback_object_type", object_name) unless options[:callback] == false
  end
  
  def s3_javascripts
    content_for(:js) { javascript_include_tag '/plupload/plupload.js', '/plupload/plupload.flash.js', '/s3_assets/uploader' }
  end
end