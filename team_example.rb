require "yaml"
require "sublayer"

# Load any Actions, Generators, and Agents
Dir[File.join(__dir__, "actions", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "generators", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "agents", "*.rb")].each { |file| require file }
Sublayer.configuration.ai_provider = Sublayer::Providers::OpenAI
Sublayer.configuration.ai_model = "o3"

images = [
  # Put the paths to your team photos here
]

# Today's date as Month, day
generated_facts = DateFactAndImagePromptGenerator.new(
  date: Date.today.strftime("%B %d")
).generate

puts "\nChoose from the following fact and image prompt options for #{Date.today.strftime("%B %d")}:\n\n"

generated_facts.each_with_index do |option, index|
  puts "#{index + 1}. #{option.fact}"
  puts "   Image style: #{option.image_prompt}"
  puts ""
end

print "Select an option (1-3): "
choice = gets.chomp.to_i

if choice >= 1 && choice <= 3
  selected_option = generated_facts[choice - 1]

  puts "\nYou selected:"
  puts "Fact: #{selected_option.fact}"
  puts "Image prompt: #{selected_option.image_prompt}"
  puts "\nGenerating images..."

  images.each do |image_path|
    result = OpenAIImageGenerationAction.new(
      image_path: image_path,
      prompt: selected_option.image_prompt,
      output_path: "./output/#{File.basename(image_path, ".*")}_openai_#{Time.now.to_i}.jpg",
    ).call

    result = GeminiImageGenerationAction.new(
      image_path: image_path,
      prompt: selected_option.image_prompt,
      output_path: "./output/#{File.basename(image_path, ".*")}_gemini_#{Time.now.to_i}.jpg",
    ).call

    puts "Generated image saved to #{result[:output_path]}"
  end
else
  puts "Invalid selection. Please run the script again and choose 1, 2, or 3."
end
