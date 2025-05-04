require "yaml"
require "sublayer"

# Load any Actions, Generators, and Agents
Dir[File.join(__dir__, "actions", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "generators", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "agents", "*.rb")].each { |file| require file }
Sublayer.configuration.ai_provider = Sublayer::Providers::OpenAI
Sublayer.configuration.ai_model = "gpt-4o"

images = [
  # Paths to your team photos here
]

# Today's date as Month, day
generated_fact = DateFactAndImagePromptGenerator.new(
  date: Date.today.strftime("%B %d")
).generate

puts generated_fact.fact

puts generated_fact.image_prompt

images.each do |image_path|
  result = OpenAIImageGenerationAction.new(
    image_path: image_path,
    prompt: generated_fact.image_prompt,
    output_path: "./output/#{File.basename(image_path, ".*")}_#{Time.now.to_i}.jpg",
  ).call

  puts "Generated image saved to #{result[:output_path]}"
end
