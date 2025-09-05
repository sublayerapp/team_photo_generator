require 'httparty'
require 'base64'
require 'json'
require 'pry'

# GeminiImageGenerationAction - Generates an image using Google's Gemini API
#
# This action takes a file path (or paths) and a prompt, then uses Gemini's image
# generation API to create a new image based on the prompt and input image(s).
#
# The action returns the raw image data along with metadata, allowing you to either
# save the image directly or process it further.
#
# Example:
#   result = GeminiImageGenerationAction.new(
#     image_path: "photo.jpg",
#     prompt: "Add a llama next to me in this photo",
#   ).call
#
#   # Save to file
#   File.binwrite("llama_photo.png", result[:image_data])
class GeminiImageGenerationAction < Sublayer::Actions::Base
  DEFAULT_MODEL = "gemini-2.5-flash-image-preview"

  def initialize(image_path:, prompt:, output_path: nil, model: DEFAULT_MODEL)
    @image_paths = image_path.is_a?(Array) ? image_path : [image_path]
    @prompt = prompt
    @output_path = output_path
    @model = model
    @api_key = ENV.fetch('GEMINI_API_KEY')
  end

  def call
    response = make_api_request
    image_data = extract_image_data(response)

    # Optionally save the image if output_path is provided
    save_image(image_data) if @output_path

    # Return both the raw image data and metadata
    {
      image_data: image_data,
      output_path: @output_path,
      success: true
    }
  end

  private

  def make_api_request
    log_info("Making request to Gemini image generation API")

    # Prepare the API endpoint
    url = "https://generativelanguage.googleapis.com/v1beta/models/#{@model}:generateContent?key=#{@api_key}"

    # Build the request body with the prompt and images
    body = build_request_body

    # Make the API call
    response = HTTParty.post(
      url,
      headers: { 'Content-Type' => 'application/json' },
      body: body.to_json
    )

    if response.success?
      log_info("Image generation successful")
      response
    else
      error_message = "Gemini API error: #{response.code} - #{response.body}"
      log_error(error_message)
      raise StandardError, error_message
    end
  rescue HTTParty::Error, StandardError => e
    log_error("API request failed: #{e.message}")
    raise e
  end

  def build_request_body
    # Create the content parts array, starting with the text prompt
    parts = [{ text: @prompt }]

    # Add each image as an inline_data part
    @image_paths.each do |path|
      parts << {
        inline_data: {
          mime_type: mime_type_for_file(path),
          data: encode_image(path)
        }
      }
    end

    # Structure the full request body according to Gemini's API format
    {
      contents: [{
        parts: parts
      }],
      generationConfig: {
        responseModalities: ["TEXT", "IMAGE"]
      }
    }
  end

  def mime_type_for_file(file_path)
    extension = File.extname(file_path).downcase
    case extension
    when '.png'
      'image/png'
    when '.jpg', '.jpeg'
      'image/jpeg'
    when '.gif'
      'image/gif'
    when '.webp'
      'image/webp'
    else
      'application/octet-stream'
    end
  end

  def encode_image(path)
    Base64.strict_encode64(File.binread(path))
  end

  def extract_image_data(response)
    # Find the first part with inline_data
    response_parts = response.dig("candidates", 0, "content", "parts")

    if response_parts.nil?
      log_error("No parts found in Gemini response")
      raise StandardError, "Invalid response format from Gemini API"
    end

    # Find the image part in the response
    image_part = response_parts.find do |part|
      part["inlineData"] && part["inlineData"]["mimeType"].to_s.start_with?("image/")
    end

    if image_part.nil?
      log_error("No image data found in Gemini response")
      raise StandardError, "No image data received in response"
    end

    # Decode the base64 image data
    Base64.decode64(image_part["inlineData"]["data"])
  end

  def save_image(image_data)
    File.binwrite(@output_path, image_data)
    log_info("Image saved to #{@output_path}")
  end

  def log_info(message, **data)
    Sublayer.configuration.logger.log(:info, message, data)
  end

  def log_error(message, **data)
    Sublayer.configuration.logger.log(:error, message, data)
  end
end
