require 'httparty'
require 'base64'

# OpenAIImageGenerationAction - Generates an image using OpenAI's image generation API
#
# This action takes a file path (or paths) and a prompt, then uses OpenAI's image
# generation API to create a new image based on the prompt.
#
# Example:
#   result = OpenAIImageGenerationAction.new(
#     image_path: "image.png",
#     prompt: "Transform into a watercolor painting",
#     output_path: "watercolor.png"
#   ).call
class OpenAIImageGenerationAction < Sublayer::Actions::Base
  def initialize(image_path:, prompt:, output_path:, size: "1024x1024", model: "gpt-image-1")
    @image_paths = image_path.is_a?(Array) ? image_path : [image_path]
    @prompt = prompt
    @output_path = output_path
    @model = model
    @size = size
  end

  def call
    retries = 0
    max_retries = 3
    
    begin
      response = HTTParty.post(
        "https://api.openai.com/v1/images/edits",
        headers: {
          "Authorization" => "Bearer #{ENV.fetch('OPENAI_API_KEY')}"
        },
        multipart: true,
        body: build_request_body,
        timeout: 120
      )

      handle_response(response)
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      retries += 1
      if retries <= max_retries
        log_info("Request timeout (attempt #{retries}/#{max_retries}), retrying...")
        sleep(2 ** retries)
        retry
      else
        log_error("Request failed after #{max_retries} retries: #{e.message}")
        raise e
      end
    rescue HTTParty::Error, StandardError => e
      log_error("API request failed: #{e.message}")
      raise e
    end
  end

  private

  def build_request_body
    body = {
      model: @model,
      prompt: @prompt,
      size: @size
    }

    # Add images as file uploads
    @image_paths.each_with_index do |path, index|
      body["image[]"] = File.new(path) if index == 0
      body["image[#{index}]"] = File.new(path) if index > 0
    end

    body
  end

  def handle_response(response)
    if response.success?
      log_info("Image generation successful", usage: response["usage"])
      save_image(response)

      {
        output_path: @output_path,
        success: true,
        usage: response["usage"]
      }
    else
      error_message = "OpenAI API error: #{response.code} - #{response.body}"
      log_error(error_message)
      raise StandardError, error_message
    end
  end

  def save_image(response)
    base64_image = response.dig("data", 0, "b64_json")
    if base64_image
      image_data = Base64.decode64(base64_image)
      File.binwrite(@output_path, image_data)
    else
      log_error("No image data in response")
      raise StandardError, "No image data received in response"
    end
  end

  def log_info(message, **data)
    Sublayer.configuration.logger.log(:info, message, data)
  end

  def log_error(message, **data)
    Sublayer.configuration.logger.log(:error, message, data)
  end
end
